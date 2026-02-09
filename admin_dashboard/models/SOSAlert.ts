import mongoose, { Schema, Document, Model } from 'mongoose';

export interface ISOSAlert extends Document {
  patientId: mongoose.Types.ObjectId;
  location: string | any; // Can be GeoJSON later
  status: 'active' | 'resolved';
  timestamp: Date;
}

const SOSAlertSchema: Schema = new Schema({
  patientId: { type: Schema.Types.ObjectId, ref: 'Patient', required: true },
  location: { type: Schema.Types.Mixed, required: true }, // String or Object
  status: { 
    type: String, 
    enum: ['active', 'resolved'], 
    default: 'active' 
  },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

const SOSAlert: Model<ISOSAlert> = mongoose.models.SOSAlert || mongoose.model<ISOSAlert>('SOSAlert', SOSAlertSchema);

export default SOSAlert;
