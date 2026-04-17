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
  status: 'online' | 'busy' | 'offline';
  otp?: string;
  otpExpiry?: Date;
  bankDetails?: {
    bankName: string;
    accountHolderName: string;
    accountNumber: string;
    ifscCode: string;
  };
}

const DoctorSchema: Schema = new Schema({
  name: { type: String },
  email: { type: String, unique: true, sparse: true },
  password: { type: String, select: false },
  phone: { type: String },
  specialization: { type: String },
  licenseNumber: { type: String },
  experienceYears: { type: Number },
  hospitalAffiliation: { type: String },
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
  consultationFee: { type: Number, default: 500 },
  consultationFees: {
    standard: { type: Number },
    emergency: { type: Number },
  },
  isAvailable: { type: Boolean, default: false },
  isEmailVerified: { type: Boolean, default: false },
  status: { 
    type: String, 
    enum: ['online', 'busy', 'offline'], 
    default: 'offline' 
  },
  otp: { type: String, select: false },
  otpExpiry: { type: Date, select: false },
  bankDetails: {
    bankName: String,
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
