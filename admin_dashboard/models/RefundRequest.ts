import mongoose, { Schema, Document, Model } from 'mongoose';

export interface IRefundRequest extends Document {
  patientId: mongoose.Types.ObjectId;
  doctorId: mongoose.Types.ObjectId;
  callRequestId: mongoose.Types.ObjectId;
  amount: number;
  reason: string;
  status: 'pending' | 'approved' | 'rejected';
  adminNote?: string;
  patientName?: string;
  doctorName?: string;
}

const RefundRequestSchema: Schema = new Schema({
  patientId: { type: Schema.Types.ObjectId, ref: 'Patient', required: true },
  doctorId: { type: Schema.Types.ObjectId, ref: 'Doctor', required: true },
  callRequestId: { type: Schema.Types.ObjectId, ref: 'CallRequest', required: true },
  amount: { type: Number, required: true },
  reason: { type: String, required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  adminNote: { type: String },
  patientName: { type: String },
  doctorName: { type: String },
}, { timestamps: true });

const RefundRequest: Model<IRefundRequest> =
  mongoose.models.RefundRequest ||
  mongoose.model<IRefundRequest>('RefundRequest', RefundRequestSchema);

export default RefundRequest;
