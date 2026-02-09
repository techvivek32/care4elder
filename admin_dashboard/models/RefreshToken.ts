import mongoose, { Schema, Document, Model } from 'mongoose';

export interface IRefreshToken extends Document {
  token: string;
  user: mongoose.Types.ObjectId;
  userModel: 'Doctor' | 'Patient' | 'Admin';
  expiresAt: Date;
  createdAt: Date;
}

const RefreshTokenSchema: Schema = new Schema({
  token: { type: String, required: true, unique: true },
  user: { type: Schema.Types.ObjectId, required: true, refPath: 'userModel' },
  userModel: { type: String, required: true, enum: ['Doctor', 'Patient', 'Admin'] },
  expiresAt: { type: Date, required: true },
  createdAt: { type: Date, default: Date.now, expires: '7d' } // Auto-delete after 7 days (matching typical refresh token life)
});

const RefreshToken: Model<IRefreshToken> = mongoose.models.RefreshToken || mongoose.model<IRefreshToken>('RefreshToken', RefreshTokenSchema);

export default RefreshToken;
