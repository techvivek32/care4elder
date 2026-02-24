import mongoose, { Schema, Document, Model } from 'mongoose';

export interface IPatient extends Document {
  name: string;
  email: string;
  password?: string;
  phone: string;
  emergencyContacts: {
    name: string;
    relation: string;
    phone: string;
  }[];
  isRelativeVerified: boolean;
  isEmailVerified: boolean;
  otp?: string;
  otpExpiry?: Date;
  medicalHistory: Record<string, any>;
  dateOfBirth?: Date;
  gender?: string;
  location?: string;
  profilePictureUrl?: string;
  bloodGroup?: string;
  allergies?: string;
  pastSurgeries?: Array<{
    procedure: string;
    date?: Date;
    documentUrl?: string;
  }>;
  currentMedications?: Array<{
    name: string;
    purpose?: string;
  }>;
  additionalInfo?: string;
  additionalDocuments?: string[];
  labReports?: string[];
  prescriptions?: string[];
  walletBalance: number;
}

const PatientSchema: Schema = new Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true, select: false },
  phone: { type: String, required: true }, // Removed unique constraint from phone to avoid conflict if email is primary auth
  emergencyContacts: [{
    name: String,
    relation: String,
    phone: String
  }],
  isRelativeVerified: { type: Boolean, default: false },
  isEmailVerified: { type: Boolean, default: false },
  otp: { type: String, select: false },
  otpExpiry: { type: Date, select: false },
  medicalHistory: { type: Object, default: {} },
  dateOfBirth: { type: Date },
  gender: { type: String, enum: ['Male', 'Female', 'Other', 'Prefer not to say'], default: undefined },
  location: { type: String },
  profilePictureUrl: { type: String },
  bloodGroup: { type: String },
  allergies: { type: String },
  pastSurgeries: [{
    procedure: { type: String, required: true },
    date: { type: Date },
    documentUrl: { type: String },
  }],
  currentMedications: [{
    name: { type: String, required: true },
    purpose: { type: String },
  }],
  additionalInfo: { type: String },
  additionalDocuments: [{ type: String }],
  labReports: [{ type: String }],
  prescriptions: [{ type: String }],
  walletBalance: { type: Number, default: 0 }
}, { timestamps: true });

const Patient: Model<IPatient> = mongoose.models.Patient || mongoose.model<IPatient>('Patient', PatientSchema);

export default Patient;
