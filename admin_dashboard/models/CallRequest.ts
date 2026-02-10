import mongoose, { Schema, Document, Model } from 'mongoose';

export interface ICallRequest extends Document {
  doctorId: mongoose.Types.ObjectId;
  patientId: mongoose.Types.ObjectId;
  status: 'ringing' | 'accepted' | 'declined' | 'cancelled' | 'timeout' | 'completed';
  consultationType: 'consultation' | 'emergency';
  fee: number;
  channelName: string;
  duration?: number; // Duration in seconds
  report?: string; // Doctor's notes/report
}

const CallRequestSchema: Schema = new Schema(
  {
    doctorId: { type: Schema.Types.ObjectId, ref: 'Doctor', required: true },
    patientId: { type: Schema.Types.ObjectId, ref: 'Patient', required: true },
    status: {
      type: String,
      enum: ['ringing', 'accepted', 'declined', 'cancelled', 'timeout', 'completed'],
      default: 'ringing',
    },
    consultationType: {
      type: String,
      enum: ['consultation', 'emergency'],
      default: 'consultation',
    },
    fee: { type: Number, required: true },
    channelName: { type: String, default: '' },
    duration: { type: Number, default: 0 },
    report: { type: String, default: '' },
  },
  { timestamps: true }
);

const CallRequest: Model<ICallRequest> =
  mongoose.models.CallRequest ||
  mongoose.model<ICallRequest>('CallRequest', CallRequestSchema);

export default CallRequest;
