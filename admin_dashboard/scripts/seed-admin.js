const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: '.env' });

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, select: false },
  role: { type: String, enum: ['admin', 'moderator'], default: 'admin' }
}, { timestamps: true });

const User = mongoose.models.User || mongoose.model('User', UserSchema);

async function seedAdmin() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('Please set MONGODB_URI in .env.local');
    process.exit(1);
  }

  try {
    await mongoose.connect(uri);
    console.log('Connected to MongoDB');

    const email = 'care4elder2026@gmail.com';
    const password = 'Care@2026'; // Change this in production
    const hashedPassword = await bcrypt.hash(password, 10);

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log('Admin user already exists');
      // Update password if user exists to ensure it matches
      existingUser.password = hashedPassword;
      await existingUser.save();
      console.log('Admin user password updated');
    } else {
      await User.create({
        name: 'Care4Elder Admin',
        email,
        password: hashedPassword,
        role: 'admin'
      });
      console.log(`Admin user created: ${email} / ${password}`);
    }

    await mongoose.disconnect();
  } catch (error) {
    console.error('Error seeding admin:', error);
    process.exit(1);
  }
}

seedAdmin();
