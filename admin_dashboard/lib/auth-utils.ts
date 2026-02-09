import jwt from 'jsonwebtoken';
import RefreshToken from '@/models/RefreshToken';

const JWT_SECRET = process.env.JWT_SECRET || process.env.NEXTAUTH_SECRET || 'fallback_secret_do_not_use_in_production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'fallback_refresh_secret_do_not_use_in_production';

export const signToken = (payload: object) => {
  // Access token: 24 hours
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '24h' });
};

export const signRefreshToken = (payload: object) => {
  // Refresh token: 30 days
  return jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: '30d' });
};

export const verifyToken = (token: string) => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
};

export const verifyRefreshToken = (token: string) => {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET);
  } catch (error) {
    return null;
  }
};

export const createRefreshToken = async (userId: string, userModel: 'Doctor' | 'Patient' | 'Admin') => {
    const token = signRefreshToken({ id: userId, role: userModel.toLowerCase() });
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);
    
    await RefreshToken.create({
        token,
        user: userId,
        userModel,
        expiresAt
    });
    
    return token;
};
