import { readFile } from 'fs/promises';
import { randomUUID } from 'crypto';
import { extname } from 'path';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

const RECIPE_IMAGES_BUCKET = 'recipe-images';

export const DEFAULT_RECIPE_IMAGE_URL =
  'https://cdmkszvzdkromgqzexec.supabase.co/storage/v1/object/public/recipe-images/default-recipe.jpg';

let storageClient: SupabaseClient | null = null;

const getStorageClient = (): SupabaseClient => {
  if (!storageClient) {
    const url = process.env.SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SUPABASE_ANON_KEY;

    if (!url || !key) {
      throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (or SUPABASE_ANON_KEY) must be set');
    }

    storageClient = createClient(url, key);
  }

  return storageClient;
};

const getFileExtension = (file: Express.Multer.File): string => {
  const extensionFromName = extname(file.originalname || '').replace('.', '').toLowerCase();
  if (extensionFromName) {
    return extensionFromName;
  }

  const extensionFromMime = file.mimetype?.split('/')[1]?.toLowerCase();
  if (extensionFromMime) {
    return extensionFromMime;
  }

  return 'jpg';
};

const getFileBytes = async (file: Express.Multer.File): Promise<Buffer> => {
  if (file.buffer && file.buffer.length > 0) {
    return file.buffer;
  }

  if (file.path) {
    return readFile(file.path);
  }

  throw new Error('Uploaded file payload is empty');
};

export const uploadImage = async (file: Express.Multer.File): Promise<string> => {
  if (!file) {
    throw new Error('No file provided');
  }

  if (!file.mimetype?.startsWith('image/')) {
    throw new Error('Only image files are supported');
  }

  const fileBytes = await getFileBytes(file);
  const fileName = `recipes/${Date.now()}-${randomUUID()}.${getFileExtension(file)}`;

  const client = getStorageClient();
  const { error } = await client.storage.from(RECIPE_IMAGES_BUCKET).upload(fileName, fileBytes, {
    contentType: file.mimetype,
    upsert: false,
  });

  if (error) {
    throw new Error(`Image upload failed: ${error.message}`);
  }

  const { data } = client.storage.from(RECIPE_IMAGES_BUCKET).getPublicUrl(fileName);

  if (!data.publicUrl) {
    throw new Error('Could not resolve public URL for uploaded image');
  }

  return data.publicUrl;
};
