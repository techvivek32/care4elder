import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT),
  secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

export const sendOTP = async (email: string, otp: string, role: 'Doctor' | 'Patient') => {
  try {
    const subject = `CareSafe - ${role} Registration OTP`;
    const title = `${role} Registration Verification`;
    
    const mailOptions = {
      from: process.env.SMTP_FROM || '"CareSafe Admin" <noreply@caresafe.com>',
      to: email,
      subject: subject,
      text: `Your OTP for ${role.toLowerCase()} registration is: ${otp}. It is valid for 10 minutes.`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>${title}</h2>
          <p>Hello,</p>
          <p>Thank you for registering with CareSafe. Please use the following OTP to verify your email address:</p>
          <h1 style="background-color: #f4f4f4; padding: 10px; text-align: center; letter-spacing: 5px;">${otp}</h1>
          <p>This OTP is valid for 10 minutes.</p>
          <p>If you did not request this, please ignore this email.</p>
          <br>
          <p>Best regards,</p>
          <p>CareSafe Team</p>
        </div>
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Message sent: %s', info.messageId);
    return true;
  } catch (error) {
    console.error('Error sending email:', error);
    return false;
  }
};

// Deprecated: Alias for backward compatibility if needed, but better to update calls
export const sendDoctorOTP = async (email: string, otp: string) => {
    return sendOTP(email, otp, 'Doctor');
}
