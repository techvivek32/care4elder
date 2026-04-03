import mongoose from 'mongoose';

const adminBroadcastSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    body: { type: String, required: true },
    type: {
      type: String,
      enum: ['emergency', 'appointment', 'tip', 'general'],
      default: 'general',
    },
    topic: { type: String, default: '' },
    audience: {
      type: String,
      enum: ['patients', 'doctors', 'both'],
      required: true,
    },
    recipientCount: { type: Number, default: 0 },
  },
  { timestamps: true }
);

const AdminBroadcast =
  mongoose.models.AdminBroadcast ||
  mongoose.model('AdminBroadcast', adminBroadcastSchema);

export default AdminBroadcast;
