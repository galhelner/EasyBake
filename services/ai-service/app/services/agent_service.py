import asyncio
from typing import Optional, AsyncIterator, Any
from google.genai import types
from google.adk import Event
from google.adk.agents.callback_context import CallbackContext
from google.adk.models.google_llm import Gemini
from google.adk.models.llm_request import LlmRequest
from google.adk.models.llm_response import LlmResponse
from google.adk.plugins import BasePlugin
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from app.agents.root_router.agent import get_root_router_agent
from app.agents.tools import auth_token_var, stream_queue_var, recipe_id_var
from app.core.logger import get_logger
from app.services.llm_service import FALLBACK_MODEL_NAME, is_fallback_worthy_error

logger = get_logger()


class ModelFallbackPlugin(BasePlugin):
    """Falls back to a secondary Gemini model on transient 503/429 model errors."""

    def __init__(self, fallback_model: str = FALLBACK_MODEL_NAME):
        super().__init__(name="model_fallback_plugin")
        self.fallback_model = fallback_model

    async def on_model_error_callback(
        self,
        *,
        callback_context: CallbackContext,
        llm_request: LlmRequest,
        error: Exception,
    ) -> Optional[LlmResponse]:
        if (
            not self.fallback_model
            or llm_request.model == self.fallback_model
            or not is_fallback_worthy_error(error)
        ):
            return None

        logger.warning(
            f"ADK model '{llm_request.model}' failed ({error}); falling back to '{self.fallback_model}'."
        )
        fallback_request = llm_request.model_copy(update={"model": self.fallback_model})
        fallback_llm = Gemini(model=self.fallback_model)
        async for response in fallback_llm.generate_content_async(fallback_request, stream=False):
            return response
        return None


class AgentService:
    def __init__(self):
        # InMemory session store and runner
        self.sessions = InMemorySessionService()
        plugins = [ModelFallbackPlugin(FALLBACK_MODEL_NAME)] if FALLBACK_MODEL_NAME else []
        self.runner = Runner(
            agent=get_root_router_agent(),
            session_service=self.sessions,
            app_name="EasyBake",
            plugins=plugins,
        )

    async def chat_stream(
        self,
        prompt: str,
        page_context: str,
        session_id: str,
        recipe_context: Optional[str] = None,
        recipe_id: Optional[str] = None,
        authorization: Optional[str] = None,
        history: Optional[list[Any]] = None,
    ) -> AsyncIterator[dict | str]:
        # 1. Setup Request Context variables
        auth_token_var.set(authorization)
        recipe_id_var.set(recipe_id)
        
        # 2. Setup the stream queue
        queue = asyncio.Queue()
        stream_queue_var.set(queue)
        
        formatted_prompt = ""
        if recipe_context:
            formatted_prompt += f"Recipe Context:\n{recipe_context}\n\n"
        formatted_prompt += f"Page Context: {page_context}\n"
        formatted_prompt += f"User message: {prompt}"
        
        logger.info(f"Incoming prompt request: prompt='{prompt}', page_context='{page_context}', session_id='{session_id}', recipe_id='{recipe_id}'")
        
        # Create an async task to run the agent
        async def run_agent():
            try:
                # Check if session already exists, else create it
                session = await self.sessions.get_session(app_name="EasyBake", user_id="default_user", session_id=session_id)
                if session is None:
                    logger.info(f"🚀 [Session Create] Initializing new agent session: {session_id}")
                    session = await self.sessions.create_session(app_name="EasyBake", user_id="default_user", session_id=session_id)
                    if history:
                        logger.info(f"🚀 Seeding new session with {len(history)} messages from history")
                        for item in history:
                            role = item.role if item.role in ["user", "model"] else "user"
                            author = "user" if role == "user" else "root_router_agent"
                            event = Event(
                                author=author,
                                message=types.Content(role=role, parts=[types.Part.from_text(text=item.content)])
                            )
                            await self.sessions.append_event(session, event)
                else:
                    logger.info(f"🚀 [Session Load] Resuming existing agent session: {session_id}")

                msg = types.Content(parts=[types.Part.from_text(text=formatted_prompt)])
                
                active_agents = set()
                async for event in self.runner.run_async(user_id="default_user", session_id=session.id, new_message=msg):
                    author = event.author
                    node_path = event.node_info.path if event.node_info else ""
                    
                    # Trace agent activation
                    if author and author != "user" and author not in active_agents:
                        active_agents.add(author)
                        logger.info(f"🚀 [Agent Activate] Specialist agent '{author}' is now active (Path: {node_path})")
                    
                    # Trace agent routing / transfer
                    if event.actions and event.actions.transfer_to_agent:
                        logger.info(f"🤖 [Agent Routing] '{author}' is delegating task to sub-agent '{event.actions.transfer_to_agent}'")
                        
                    # Trace agent escalation
                    if event.actions and event.actions.escalate:
                        logger.info(f"↩️ [Agent Escalation] '{author}' is returning control to parent agent")
                        
                    # Trace tool/function calls
                    function_calls = event.get_function_calls()
                    if function_calls:
                        for fc in function_calls:
                            logger.info(f"🔧 [Tool Call] Agent '{author}' is calling tool '{fc.name}' with arguments: {fc.args}")
                            
                    # Trace tool/function responses
                    function_responses = event.get_function_responses()
                    if function_responses:
                        for fr in function_responses:
                            logger.info(f"✅ [Tool Response] Tool '{fr.name}' returned success: {str(fr.response)[:150]}...")
                    
                    text_chunk = None
                    if event.content and event.content.parts:
                        for part in event.content.parts:
                            t = getattr(part, "text", None)
                            if t:
                                text_chunk = t
                                break
                                
                    if text_chunk:
                        logger.info(f"💬 [Agent Response Chunk] '{author}': '{text_chunk}'")
                        await queue.put({"type": "text", "delta": text_chunk})
     
                logger.info(f"🏁 [Agent Finished] Multi-Agent session execution completed.")
            except Exception as e:
                logger.error(f"Agent stream run failed: {e}")
                await queue.put({"type": "error", "message": "AI assistant encountered an error. Please try again."})
            finally:
                await queue.put("[DONE]")
                
        # Start the runner task in the background
        asyncio.create_task(run_agent())
        
        while True:
            item = await queue.get()
            yield item
            if item == "[DONE]":
                break


# Global singleton instance of AgentService
agent_service = AgentService()
