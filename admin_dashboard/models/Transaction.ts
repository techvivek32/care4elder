import mongoose, { Schema, Document, Model } from 'mongoose';

export interface ITransaction extends Document {
  patientId: mongoose.Types.ObjectId;
  type: 'credit' | 'debit';
  amount: number;
  description: string;
  paymentId?: string; // Razorpay payment ID
  balanceAfter: number;
  timestamp: Date;
}

const TransactionSchema: Schema = new Schema({
  patientId: { type: Schema.Types.ObjectId, ref: 'Patient', required: true },
  type: { type: String, enum: ['credit', 'debit'], required: true },
  amount: { type: Number, required: true },
  description: { type: String, required: true },
  paymentId: { type: String },
  balanceAfter: { type: Number, required: true },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

// Check if model exists before compiling
if (process.env.NODE_ENV === 'development' && mongoose.models.Transaction) {
  delete mongoose.models.Transaction;
}

const Transaction: Model<ITransaction> = mongoose.models.Transaction || mongoose.model<ITransaction>('Transaction', TransactionSchema);

export default Transaction;
