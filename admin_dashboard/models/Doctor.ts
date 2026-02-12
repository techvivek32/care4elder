import mongoose, { Schema, Document, Model } from 'mongoose';

export interface IDoctor extends Document {
  name: string;
  email: string;
  password?: string;
  phone: string;
  specialization: string;
  licenseNumber: string;
  experienceYears?: number;
  hospitalAffiliation?: string;
  idNumber?: string;
  qualifications?: string;
  experience?: string;
  about?: string;
  profileImage?: string;
  verificationStatus: 'pending' | 'approved' | 'rejected';
  documents: string[];
  walletBalance: number;
  rating: number;
  reviews: number;
  consultationFee: number;
  consultationFees?: {
    standard: number;
    emergency: number;
  };
  isAvailable: boolean;
  isEmailVerified: boolean;
  otp?: string;
  otpExpiry?: Date;
  bankDetails?: {
    accountHolderName: string;
    accountNumber: string;
    ifscCode: string;
  };
}

const DoctorSchema: Schema = new Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true, select: false },
  phone: { type: String, required: true },
  specialization: { type: String, required: true },
  licenseNumber: { type: String, required: true },
  experienceYears: { type: Number },
  hospitalAffiliation: { type: String },
  idNumber: { type: String },
  qualifications: { type: String },
  experience: { type: String },
  about: { type: String },
  profileImage: { type: String },
  verificationStatus: { 
    type: String, 
    enum: ['pending', 'approved', 'rejected'], 
    default: 'pending' 
  },
  documents: [{ type: String }],
  walletBalance: { type: Number, default: 0 },
  rating: { type: Number, default: 0 },
  reviews: { type: Number, default: 0 },
  consultationFee: { type: Number, required: true }, // Keep for backward compatibility
  consultationFees: {
    standard: { type: Number },
    emergency: { type: Number },
  },
  isAvailable: { type: Boolean, default: false },
  isEmailVerified: { type: Boolean, default: false },
  otp: { type: String, select: false },
  otpExpiry: { type: Date, select: false },
  bankDetails: {
    accountHolderName: String,
    accountNumber: String,
    ifscCode: String,
  }
}, { timestamps: true });

// Check if model exists before compiling
// In development, we might need to delete the model to force a refresh if schema changes
if (process.env.NODE_ENV === 'development' && mongoose.models.Doctor) {
  delete mongoose.models.Doctor;
}

const Doctor: Model<IDoctor> = mongoose.models.Doctor || mongoose.model<IDoctor>('Doctor', DoctorSchema);

export default Doctor;
