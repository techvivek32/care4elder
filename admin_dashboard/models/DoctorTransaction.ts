import mongoose, { Schema, Document, Model } from 'mongoose';

export interface IDoctorTransaction extends Document {
  doctorId: mongoose.Types.ObjectId;
  type: 'credit' | 'debit';
  amount: number;
  description: string;
  balanceAfter: number;
  metadata?: Record<string, unknown>;
  createdAt: Date;
}

const DoctorTransactionSchema: Schema = new Schema({
  doctorId: { type: Schema.Types.ObjectId, ref: 'Doctor', required: true },
  type: { type: String, enum: ['credit', 'debit'], required: true },
  amount: { type: Number, required: true },
  description: { type: String, required: true },
  balanceAfter: { type: Number, required: true },
  metadata: { type: Schema.Types.Mixed },
}, { timestamps: true });

const DoctorTransaction: Model<IDoctorTransaction> =
  mongoose.models.DoctorTransaction ||
  mongoose.model<IDoctorTransaction>('DoctorTransaction', DoctorTransactionSchema);

export default DoctorTransaction;
