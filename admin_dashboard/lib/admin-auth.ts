import type { NextRequest } from 'next/server';
import { getServerSession } from 'next-auth/next';
import { getToken } from 'next-auth/jwt';
import { authOptions } from '@/lib/auth';

/**
 * Resolve dashboard admin/moderator user for admin API routes (session cookie or JWT).
 */
export async function getAdminAuthUser(request: NextRequest): Promise<{
  id: string;
  role: string;
} | null> {
  try {
    const session = await getServerSession(authOptions);
    if (session?.user) {
      const role = (session.user as { role?: string }).role || 'admin';
      if (role === 'admin' || role === 'moderator') {
        return { id: (session.user as { id: string }).id, role };
      }
      return null;
    }

    const token = await getToken({
      req: request as any,
      secret: process.env.NEXTAUTH_SECRET,
    });
    if (token) {
      const role = (token.role as string) || 'admin';
      if (role === 'admin' || role === 'moderator') {
        return { id: token.id as string, role };
      }
    }
  } catch (e) {
    console.error('getAdminAuthUser error:', e);
  }
  return null;
}
