import mongoose, { Schema, Document } from 'mongoose';

export interface IOtp extends Document {
  email: string;
  otp: string;
  role: string;
  isVerified: boolean;
  createdAt: Date;
}

const OtpSchema: Schema = new Schema({
  email: { type: String, required: true },
  otp: { type: String, required: true },
  role: { type: String, required: true, enum: ['Doctor', 'Patient'] },
  isVerified: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now, expires: 600 } // Auto-delete after 10 minutes
});

// Compound index to ensure unique email per role? Or just email?
// A user might try to register as Doctor and Patient with same email? 
// Schema allows duplicates, but we usually want latest OTP.
// We'll handle upsert in the API.

export default mongoose.models.Otp || mongoose.model<IOtp>('Otp', OtpSchema);
