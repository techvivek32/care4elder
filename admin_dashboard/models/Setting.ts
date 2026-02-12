import mongoose from 'mongoose';

const SettingSchema = new mongoose.Schema({
  razorpayKeyId: {
    type: String,
    default: '',
  },
  razorpayKeySecret: {
    type: String,
    default: '',
  },
  standardCommission: {
    type: Number,
    default: 0,
  },
  emergencyCommission: {
    type: Number,
    default: 0,
  },
}, { timestamps: true });

// Check if the model exists before compiling it
const Setting = mongoose.models.Setting || mongoose.model('Setting', SettingSchema);

export default Setting;
