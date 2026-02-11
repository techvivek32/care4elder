import mongoose from 'mongoose';

const HeroSectionSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  subtitle: {
    type: String,
    default: '',
  },
  imageUrl: {
    type: String,
    required: true,
  },
  order: {
    type: Number,
    default: 0,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  type: {
    type: String,
    enum: ['patient', 'doctor', 'both'],
    default: 'both',
  },
}, { timestamps: true });

const HeroSection = mongoose.models.HeroSection || mongoose.model('HeroSection', HeroSectionSchema);

export default HeroSection;
