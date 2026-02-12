import mongoose, { Schema, Document, Model } from 'mongoose';

export interface IWithdrawalRequest extends Document {
  doctorId: mongoose.Types.ObjectId;
  amount: number;
  status: 'pending' | 'approved' | 'declined' | 'credited';
  bankDetails: {
    accountHolderName: string;
    accountNumber: string;
    ifscCode: string;
  };
  rejectionReason?: string;
  createdAt: Date;
  updatedAt: Date;
}

const WithdrawalRequestSchema: Schema = new Schema({
  doctorId: { type: Schema.Types.ObjectId, ref: 'Doctor', required: true },
  amount: { type: Number, required: true },
  status: { 
    type: String, 
    enum: ['pending', 'approved', 'declined', 'credited'], 
    default: 'pending' 
  },
  bankDetails: {
    accountHolderName: { type: String, required: true },
    accountNumber: { type: String, required: true },
    ifscCode: { type: String, required: true },
  },
  rejectionReason: { type: String },
}, { timestamps: true });

const WithdrawalRequest: Model<IWithdrawalRequest> = mongoose.models.WithdrawalRequest || mongoose.model<IWithdrawalRequest>('WithdrawalRequest', WithdrawalRequestSchema);

export default WithdrawalRequest;
