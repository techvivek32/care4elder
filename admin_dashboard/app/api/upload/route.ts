import { NextResponse } from 'next/server';
import { writeFile, mkdir } from 'fs/promises';
import path from 'path';

export async function POST(req: Request) {
  try {
    const formData = await req.formData();
    const files = formData.getAll('file') as File[];

    if (!files || files.length === 0) {
      return NextResponse.json({ error: 'No files uploaded' }, { status: 400 });
    }

    const uploadDir = path.join(process.cwd(), 'public', 'uploads');
    
    // Ensure upload directory exists
    try {
        await mkdir(uploadDir, { recursive: true });
    } catch (e) {
        // Ignore error if directory already exists
    }

    const uploadedUrls = [];

    for (const file of files) {
      const bytes = await file.arrayBuffer();
      const buffer = Buffer.from(bytes);

      // Generate unique filename
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      const filename = file.name.replace(/\s+/g, '-').toLowerCase();
      const finalName = `${uniqueSuffix}-${filename}`;
      const filepath = path.join(uploadDir, finalName);

      await writeFile(filepath, buffer);
      
      // Construct public URL (assuming Next.js serves static from public/)
      // If deployed, this needs to be adjusted. For localhost, it works.
      const fileUrl = `/uploads/${finalName}`;
      uploadedUrls.push(fileUrl);
    }

    return NextResponse.json({ urls: uploadedUrls }, { status: 200 });

  } catch (error) {
    console.error('Upload Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
