import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import SOSAlert from '@/models/SOSAlert';
import Patient from '@/models/Patient'; // Ensure Patient model is registered

export async function GET(request: Request) {
  try {
    await dbConnect();
    
    // Ensure models are registered
    if (!Patient) {
      throw new Error('Patient model not loaded');
    }

    // Fetch all alerts (active and resolved), sorted by status (active first) then timestamp
    const alerts = await SOSAlert.find({})
      .populate('patientId', 'name phone emergencyContacts')
      .sort({ status: 1, timestamp: -1 }); // 'active' comes before 'resolved' alphabetically? No, 'a' < 'r'. So 1 is ascending.
      
    return NextResponse.json(alerts);
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Failed to fetch SOS alerts' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    await dbConnect();
    const body = await request.json();
    
    // Create new alert
    const alert = await SOSAlert.create({
      patientId: body.patientId,
      location: body.location,
      status: 'active',
      timestamp: new Date()
    });
    
    return NextResponse.json(alert, { status: 201 });
  } catch (error) {
    console.error('Error creating SOS alert:', error);
    return NextResponse.json({ error: 'Failed to create SOS alert' }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
    try {
        await dbConnect();
        const body = await request.json();
        console.log('PATCH /api/sos received:', body); // Debug log

        const { id, status, callStatus } = body;
        
        if (!id) {
            console.error('Missing ID in PATCH request');
            return NextResponse.json({ error: 'Alert ID is required' }, { status: 400 });
        }

        const updateData: any = {};
        if (status) updateData.status = status;
        
        // Handle granular updates for callStatus using dot notation (Flattened for safety)
        if (callStatus) {
            if (callStatus.patient) {
                if (callStatus.patient.status) {
                    updateData['callStatus.patient.status'] = callStatus.patient.status;
                }
                if (callStatus.patient.remark !== undefined) {
                    updateData['callStatus.patient.remark'] = callStatus.patient.remark;
                }
            }
            if (callStatus.emergencyContact) {
                if (callStatus.emergencyContact.status) {
                    updateData['callStatus.emergencyContact.status'] = callStatus.emergencyContact.status;
                }
                if (callStatus.emergencyContact.remark !== undefined) {
                    updateData['callStatus.emergencyContact.remark'] = callStatus.emergencyContact.remark;
                }
            }
            if (callStatus.service) {
                if (callStatus.service.remark !== undefined) {
                    updateData['callStatus.service.remark'] = callStatus.service.remark;
                }
                if (callStatus.service.selectedServices) {
                    updateData['callStatus.service.selectedServices'] = callStatus.service.selectedServices;
                }
            }
        }

        console.log('Updating SOSAlert with:', updateData); // Debug log

        const alert = await SOSAlert.findByIdAndUpdate(
            id, 
            { $set: updateData }, 
            { new: true, runValidators: true } 
        ).populate('patientId', 'name phone emergencyContacts'); // Return populated document

        if (!alert) {
            console.error('Alert not found for ID:', id);
            return NextResponse.json({ error: 'Alert not found' }, { status: 404 });
        }

        console.log('Updated alert:', alert); // Debug log
        return NextResponse.json(alert);
    } catch (error: any) {
        console.error('Failed to update alert:', error);
        return NextResponse.json({ error: 'Failed to update alert', details: error.message }, { status: 500 });
    }
}
