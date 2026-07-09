import { Response } from 'express';
import { z } from 'zod';
import prisma from '../services/prismaClient';
import { AuthenticatedRequest } from '../middleware/authMiddleware';

const ensureUser = async (authId: string) => {
  const existingUser = await prisma.user.findUnique({
    where: { authId },
    select: { id: true },
  });

  if (existingUser) {
    return existingUser;
  }

  return prisma.user.create({
    data: { authId },
    select: { id: true },
  });
};

const createFolderSchema = z.object({
  name: z.string().trim().min(1),
  parentId: z.string().uuid().optional().nullable(),
});

const updateFolderSchema = z.object({
  name: z.string().trim().min(1).optional(),
  parentId: z.string().uuid().optional().nullable(),
});

export const createFolder = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const parsed = createFolderSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
      return;
    }

    const user = await ensureUser(req.user.id);
    const { name, parentId } = parsed.data;

    if (parentId) {
      const parentFolder = await prisma.folder.findFirst({
        where: { id: parentId, userId: user.id },
      });
      if (!parentFolder) {
        res.status(404).json({ error: 'Parent folder not found' });
        return;
      }
    }

    const folder = await prisma.folder.create({
      data: {
        name,
        userId: user.id,
        parentId: parentId || null,
      },
    });

    res.status(201).json(folder);
  } catch (error) {
    console.error('Error creating folder', error);
    res.status(500).json({ error: 'Failed to create folder' });
  }
};

export const getFolders = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const user = await ensureUser(req.user.id);

    const folders = await prisma.folder.findMany({
      where: { userId: user.id },
      orderBy: { name: 'asc' },
    });

    res.json(folders);
  } catch (error) {
    console.error('Error fetching folders', error);
    res.status(500).json({ error: 'Failed to fetch folders' });
  }
};

export const updateFolder = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const parsed = updateFolderSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
      return;
    }

    const { id } = req.params;
    const user = await ensureUser(req.user.id);

    const folder = await prisma.folder.findFirst({
      where: { id, userId: user.id },
    });

    if (!folder) {
      res.status(404).json({ error: 'Folder not found' });
      return;
    }

    const { name, parentId } = parsed.data;

    if (parentId !== undefined) {
      if (parentId === folder.id) {
        res.status(400).json({ error: 'Cannot set parent to itself' });
        return;
      }

      if (parentId) {
        const parentFolder = await prisma.folder.findFirst({
          where: { id: parentId, userId: user.id },
        });
        if (!parentFolder) {
          res.status(404).json({ error: 'Parent folder not found' });
          return;
        }

        let currentParentId: string | null = parentId;
        while (currentParentId) {
          const parentObj: { parentId: string | null } | null = await prisma.folder.findUnique({
            where: { id: currentParentId },
            select: { parentId: true },
          });
          if (!parentObj) break;
          if (parentObj.parentId === folder.id) {
            res.status(400).json({ error: 'Cannot move folder to its own descendant' });
            return;
          }
          currentParentId = parentObj.parentId;
        }
      }
    }

    const updated = await prisma.folder.update({
      where: { id: folder.id },
      data: {
        ...(name !== undefined ? { name } : {}),
        ...(parentId !== undefined ? { parentId: parentId || null } : {}),
      },
    });

    res.json(updated);
  } catch (error) {
    console.error('Error updating folder', error);
    res.status(500).json({ error: 'Failed to update folder' });
  }
};

const getDescendantFolderIds = async (folderId: string): Promise<string[]> => {
  const children = await prisma.folder.findMany({
    where: { parentId: folderId },
    select: { id: true },
  });
  let ids = children.map((c) => c.id);
  for (const child of children) {
    const childIds = await getDescendantFolderIds(child.id);
    ids = ids.concat(childIds);
  }
  return ids;
};

export const deleteFolder = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { id } = req.params;
    const purge = req.query.purge === 'true';

    const user = await ensureUser(req.user.id);

    const folder = await prisma.folder.findFirst({
      where: { id, userId: user.id },
    });

    if (!folder) {
      res.status(404).json({ error: 'Folder not found' });
      return;
    }

    if (purge) {
      const allFolderIds = [folder.id, ...(await getDescendantFolderIds(folder.id))];

      await prisma.recipe.deleteMany({
        where: { folderId: { in: allFolderIds } },
      });

      await prisma.folder.delete({
        where: { id: folder.id },
      });
    } else {
      await prisma.recipe.updateMany({
        where: { folderId: folder.id },
        data: { folderId: folder.parentId },
      });

      await prisma.folder.updateMany({
        where: { parentId: folder.id },
        data: { parentId: folder.parentId },
      });

      await prisma.folder.delete({
        where: { id: folder.id },
      });
    }

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting folder', error);
    res.status(500).json({ error: 'Failed to delete folder' });
  }
};
