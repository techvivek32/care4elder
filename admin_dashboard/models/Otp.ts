import mongoose, { Schema, Document } from 'mongoose';

export interface IOtp extends Document {
  email?: string;
  phone?: string;
  otp: string;
  role: string;
  isVerified: boolean;
  createdAt: Date;
}

const OtpSchema: Schema = new Schema({
  email: { type: String },
  phone: { type: String },
  otp: { type: String, required: true },
  role: { type: String, required: true, enum: ['Doctor', 'Patient'] },
  isVerified: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now, expires: 600 } // Auto-delete after 10 minutes
});

// Check if model exists before compiling
if (process.env.NODE_ENV === 'development' && mongoose.models.Otp) {
  delete mongoose.models.Otp;
}

export default mongoose.models.Otp || mongoose.model<IOtp>('Otp', OtpSchema);
