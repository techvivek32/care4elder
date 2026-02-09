import mongoose, { Schema, Document, Model } from 'mongoose';

export interface IAppointment extends Document {
  doctorId: mongoose.Types.ObjectId;
  patientId: mongoose.Types.ObjectId;
  status: 'pending' | 'scheduled' | 'completed' | 'cancelled';
  dateTime: Date;
  amount: number;
}

const AppointmentSchema: Schema = new Schema({
  doctorId: { type: Schema.Types.ObjectId, ref: 'Doctor', required: true },
  patientId: { type: Schema.Types.ObjectId, ref: 'Patient', required: true },
  status: { 
    type: String, 
    enum: ['pending', 'scheduled', 'completed', 'cancelled'], 
    default: 'pending' 
  },
  dateTime: { type: Date, required: true },
  amount: { type: Number, required: true }
}, { timestamps: true });

const Appointment: Model<IAppointment> = mongoose.models.Appointment || mongoose.model<IAppointment>('Appointment', AppointmentSchema);

export default Appointment;
