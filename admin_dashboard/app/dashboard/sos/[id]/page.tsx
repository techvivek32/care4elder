'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useParams, useRouter } from 'next/navigation';
import { MapPin, Phone, User, Clock, AlertTriangle, ArrowLeft, Stethoscope, CheckCircle, XCircle, Save } from 'lucide-react';
import Link from 'next/link';
import { useState, useEffect } from 'react';

async function fetchSOSDetail(id: string) {
  const res = await fetch(`/api/sos/${id}`);
  if (!res.ok) throw new Error('Failed to fetch SOS detail');
  return res.json();
}

export default function SOSDetailPage() {
  const { id } = useParams();
  const router = useRouter();
  
  const { data: alertData, isLoading, error, refetch } = useQuery({
    queryKey: ['sos-detail', id],
    queryFn: () => fetchSOSDetail(id as string),
    enabled: !!id,
    // Removed refetchInterval to prevent overwriting form state while editing
  });

  const queryClient = useQueryClient();
  
  // Local state for form inputs
  const [localCallStatus, setLocalCallStatus] = useState({
    patient: { status: 'pending', remark: '' },
    emergencyContact: { status: 'pending', remark: '' },
    service: { remark: '' }
  });

  // Sync with server data
  useEffect(() => {
    if (alertData?.callStatus) {
      setLocalCallStatus({
        patient: { 
          status: alertData.callStatus.patient?.status || 'pending', 
          remark: alertData.callStatus.patient?.remark || '' 
        },
        emergencyContact: { 
          status: alertData.callStatus.emergencyContact?.status || 'pending', 
          remark: alertData.callStatus.emergencyContact?.remark || '' 
        },
        service: { 
          remark: alertData.callStatus.service?.remark || '' 
        }
      });
    }
  }, [alertData]);

  const updateStatusMutation = useMutation({
    mutationFn: async (updatePayload: any) => {
      const res = await fetch('/api/sos', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          id: alertData._id, 
          ...updatePayload
        })
      });
      if (!res.ok) throw new Error('Failed to update status');
      return res.json();
    },
    onSuccess: (updatedAlert) => {
      // Update the cache immediately with the server response
      queryClient.setQueryData(['sos-detail', id], updatedAlert);
      
      // Also invalidate to ensure consistency
      queryClient.invalidateQueries({ queryKey: ['sos-detail', id] });
      
      // alert('Status saved successfully!'); 
    },
    onError: (err: any) => {
      console.error('Status update failed:', err);
      window.alert(`Failed to update status: ${err.message}`);
    }
  });

  const handleSave = (section: 'patient' | 'emergencyContact' | 'service') => {
    console.log('handleSave called for section:', section);
    
    // Construct payload with ONLY the relevant section to ensure granular updates
    const payload: any = {
        callStatus: {}
    };

    // Deep copy current local state for the section we are saving
    if (section === 'patient') {
        let patientStatus = { ...localCallStatus.patient };
        // Auto-skip logic
        if (patientStatus.status === 'picked_up') {
            console.log('Patient picked up, skipping emergency contact (logic handled on next step/server)');
            // We don't need to set emergencyContact here because we are only sending patient status.
            // But if we want to force skip emergency contact on the server, we might need to send it.
            // However, keeping it simple: Just save patient status.
            // The visibility logic relies on patient status.
            // If we want to strictly skip emergency contact in the DB:
            payload.callStatus.emergencyContact = { status: 'skipped', remark: 'Auto-skipped: Patient picked up' };
        }
        payload.callStatus.patient = patientStatus;
    } else if (section === 'emergencyContact') {
        payload.callStatus.emergencyContact = { ...localCallStatus.emergencyContact };
    } else if (section === 'service') {
        payload.callStatus.service = { ...localCallStatus.service };
    }
    
    console.log('Sending mutation with payload:', payload);
    updateStatusMutation.mutate(payload);
  };

  if (isLoading) return <div className="p-8 text-center">Loading alert details...</div>;
  if (error) return <div className="p-8 text-center text-red-600">Error loading alert details</div>;
  if (!alertData) return <div className="p-8 text-center">Alert not found</div>;

  const patient = alertData.patientId;

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center space-x-4">
        <Link href="/dashboard/sos" className="p-2 hover:bg-gray-100 rounded-full">
          <ArrowLeft className="h-6 w-6 text-black" />
        </Link>
        <h1 className="text-2xl font-bold text-black">Emergency Alert Details</h1>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Patient Info, Contacts, Status */}
        <div className="space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center text-black">
              <User className="mr-2 h-5 w-5 text-gray-700" /> Patient Information
            </h2>
            <div className="space-y-4">
              <div className="flex items-center">
                <div className="h-12 w-12 rounded-full bg-gray-200 flex items-center justify-center mr-4 overflow-hidden">
                  {patient?.profilePictureUrl ? (
                    <img src={patient.profilePictureUrl} alt={patient.name} className="h-full w-full object-cover" />
                  ) : (
                    <span className="text-xl font-bold text-black">{patient?.name?.[0]}</span>
                  )}
                </div>
                <div>
                  <p className="font-bold text-lg text-black">{patient?.name}</p>
                  <p className="text-sm text-black">{patient?.email}</p>
                </div>
              </div>
              
              <div className="pt-4 border-t border-gray-100 space-y-3">
                <div className="flex justify-between">
                  <span className="text-black">Phone</span>
                  <span className="font-medium text-black">{patient?.phone}</span>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center text-black">
              <Phone className="mr-2 h-5 w-5 text-blue-600" /> Emergency Contacts
            </h2>
            <div className="space-y-4">
              {patient?.emergencyContacts?.map((contact: any, index: number) => (
                <div key={index} className="flex items-start p-4 bg-gray-50 rounded-lg">
                  <div className="bg-blue-100 p-2 rounded-full mr-4">
                    <User className="h-5 w-5 text-blue-600" />
                  </div>
                  <div>
                    <p className="font-medium text-black">{contact.name}</p>
                    <p className="text-sm text-black">{contact.relation}</p>
                    <p className="text-sm font-mono text-blue-600 mt-1">{contact.phone}</p>
                  </div>
                </div>
              ))}
              {(!patient?.emergencyContacts || patient.emergencyContacts.length === 0) && (
                <p className="text-black italic">No emergency contacts listed.</p>
              )}
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center text-black">
              <Clock className="mr-2 h-5 w-5 text-orange-500" /> Alert Status
            </h2>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-black">Status</span>
                <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                  alertData.status === 'active' ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'
                }`}>
                  {alertData.status.toUpperCase()}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-black">Started At</span>
                <span className="font-medium text-sm text-black">
                  {new Date(alertData.timestamp).toLocaleString()}
                </span>
              </div>
              
              {alertData.status === 'active' && (
                <div className="pt-4 mt-4 border-t border-gray-100">
                  <p className="text-sm text-black mb-3">
                    Once the emergency is handled, mark this alert as resolved.
                  </p>
                  <button 
                    className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-lg transition-colors flex items-center justify-center"
                    onClick={async () => {
                      if (confirm('Are you sure you want to resolve this SOS alert?')) {
                        await fetch('/api/sos', {
                          method: 'PATCH',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify({ id: alertData._id, status: 'resolved' })
                        });
                        router.refresh();
                      }
                    }}
                  >
                    <CheckCircle className="mr-2 h-4 w-4" /> Mark as Resolved
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Right Column: Map & Recent Doctors */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center text-black justify-between">
              <span className="flex items-center"><MapPin className="mr-2 h-5 w-5 text-red-600" /> Live Location</span>
              <button onClick={() => refetch()} className="text-xs bg-gray-200 hover:bg-gray-300 px-2 py-1 rounded text-black">Refresh Map</button>
            </h2>
            <div className="bg-gray-100 rounded-lg h-96 flex items-center justify-center relative overflow-hidden">
               {alertData.location?.lat && alertData.location?.lng ? (
                 <iframe
                   width="100%"
                   height="100%"
                   frameBorder="0"
                   style={{ border: 0 }}
                   src={`https://maps.google.com/maps?q=${alertData.location.lat},${alertData.location.lng}&z=15&output=embed`}
                   allowFullScreen
                 ></iframe>
               ) : (
                 <div className="text-center p-6">
                   <MapPin className="h-12 w-12 text-red-500 mx-auto mb-2 animate-bounce" />
                   <p className="font-mono text-lg">{typeof alertData.location === 'string' ? alertData.location : JSON.stringify(alertData.location)}</p>
                 </div>
               )}
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center text-black">
              <Stethoscope className="mr-2 h-5 w-5 text-green-600" /> Recent Doctors
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {alertData.doctors?.map((doctor: any, index: number) => (
                <div key={index} className="flex items-center p-4 bg-gray-50 rounded-lg">
                  <div className="h-12 w-12 rounded-full bg-green-100 flex items-center justify-center mr-4 overflow-hidden">
                     {doctor.profileImage ? (
                        <img src={doctor.profileImage} alt={doctor.name} className="h-full w-full object-cover" />
                     ) : (
                        <Stethoscope className="h-6 w-6 text-green-600" />
                     )}
                  </div>
                  <div>
                    <p className="font-medium text-black">{doctor.name}</p>
                    <p className="text-sm text-black">{doctor.specialization}</p>
                    <p className="text-sm font-mono text-green-600 mt-1">{doctor.phone}</p>
                  </div>
                </div>
              ))}
              {(!alertData.doctors || alertData.doctors.length === 0) && (
                <p className="text-black italic">No recent doctors found.</p>
              )}
            </div>
          </div>
        </div>
      </div>
      {/* Emergency Handling Workflow */}
      <div className="mt-8 bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 className="text-xl font-bold mb-6 text-black flex items-center">
           <AlertTriangle className="mr-2 h-6 w-6 text-orange-500" /> Emergency Handling Workflow
        </h2>
        
        <div className="space-y-8">
           {/* Step 1: Patient Call Status */}
           <div className="bg-gray-50 p-6 rounded-lg border border-gray-200">
              <h3 className="text-lg font-semibold text-black mb-4 flex items-center">
                 <span className="bg-black text-white rounded-full w-8 h-8 flex items-center justify-center mr-3 text-sm">1</span>
                 Patient Call Status
              </h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                 <div>
                    <label className="block text-sm font-medium text-black mb-1">Call Status</label>
                    <select 
                       className="w-full border-gray-300 rounded-md shadow-sm p-2 text-black"
                       value={localCallStatus.patient.status}
                       onChange={(e) => setLocalCallStatus({...localCallStatus, patient: {...localCallStatus.patient, status: e.target.value}})}
                    >
                       <option value="pending">Select Status</option>
                       <option value="picked_up">Picked Up</option>
                       <option value="not_picked_up">Not Picked Up</option>
                    </select>
                 </div>
                 <div>
                    <label className="block text-sm font-medium text-black mb-1">Remarks</label>
                    <input 
                       type="text" 
                       className="w-full border-gray-300 rounded-md shadow-sm p-2 text-black"
                       placeholder="Enter remarks..."
                       value={localCallStatus.patient.remark}
                       onChange={(e) => setLocalCallStatus({...localCallStatus, patient: {...localCallStatus.patient, remark: e.target.value}})}
                    />
                 </div>
              </div>
              <div className="mt-4 flex justify-end">
                 <button 
                    onClick={() => handleSave('patient')}
                    disabled={updateStatusMutation.isPending}
                    className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center disabled:opacity-50 disabled:cursor-not-allowed"
                 >
                    {updateStatusMutation.isPending ? 'Saving...' : (
                        <>
                            <Save className="h-4 w-4 mr-2" /> 
                            {alertData?.callStatus?.patient?.status && alertData.callStatus.patient.status !== 'pending' ? 'Update' : 'Save & Next'}
                        </>
                    )}
                 </button>
              </div>
           </div>

           {/* Step 2: Emergency Contact Call Status */}
           {alertData?.callStatus?.patient?.status === 'not_picked_up' && (
              <div className="bg-gray-50 p-6 rounded-lg border border-gray-200">
                 <h3 className="text-lg font-semibold text-black mb-4 flex items-center">
                    <span className="bg-black text-white rounded-full w-8 h-8 flex items-center justify-center mr-3 text-sm">2</span>
                    Emergency Contact Call Status
                 </h3>
                 <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                       <label className="block text-sm font-medium text-black mb-1">Call Status</label>
                       <select 
                          className="w-full border-gray-300 rounded-md shadow-sm p-2 text-black"
                          value={localCallStatus.emergencyContact.status}
                          onChange={(e) => setLocalCallStatus({...localCallStatus, emergencyContact: {...localCallStatus.emergencyContact, status: e.target.value}})}
                       >
                          <option value="pending">Select Status</option>
                          <option value="picked_up">Picked Up</option>
                          <option value="not_picked_up">Not Picked Up</option>
                       </select>
                    </div>
                    <div>
                       <label className="block text-sm font-medium text-black mb-1">Remarks</label>
                       <input 
                          type="text" 
                          className="w-full border-gray-300 rounded-md shadow-sm p-2 text-black"
                          placeholder="Enter remarks..."
                          value={localCallStatus.emergencyContact.remark}
                          onChange={(e) => setLocalCallStatus({...localCallStatus, emergencyContact: {...localCallStatus.emergencyContact, remark: e.target.value}})}
                       />
                    </div>
                 </div>
                 <div className="mt-4 flex justify-end">
                    <button 
                       onClick={() => handleSave('emergencyContact')}
                       disabled={updateStatusMutation.isPending}
                       className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                       {updateStatusMutation.isPending ? 'Saving...' : (
                           <>
                               <Save className="h-4 w-4 mr-2" /> 
                               {alertData?.callStatus?.emergencyContact?.status && alertData.callStatus.emergencyContact.status !== 'pending' ? 'Update' : 'Save & Next'}
                           </>
                       )}
                    </button>
                 </div>
              </div>
           )}

           {/* Step 3: Service Status */}
           {(alertData?.callStatus?.patient?.status === 'picked_up' || (alertData?.callStatus?.patient?.status === 'not_picked_up' && alertData?.callStatus?.emergencyContact?.status !== 'pending')) && (
              <div className="bg-gray-50 p-6 rounded-lg border border-gray-200">
                 <h3 className="text-lg font-semibold text-black mb-4 flex items-center">
                    <span className="bg-black text-white rounded-full w-8 h-8 flex items-center justify-center mr-3 text-sm">3</span>
                    Service / Action Taken
                 </h3>
                 <div>
                    <label className="block text-sm font-medium text-black mb-1">Service Remarks</label>
                    <textarea 
                       className="w-full border-gray-300 rounded-md shadow-sm p-2 text-black"
                       rows={3}
                       placeholder="Describe the action taken (e.g., Ambulance dispatched, Doctor consulted)..."
                       value={localCallStatus.service.remark}
                       onChange={(e) => setLocalCallStatus({...localCallStatus, service: {...localCallStatus.service, remark: e.target.value}})}
                    />
                 </div>
                 <div className="mt-4 flex justify-end">
                    <button 
                       onClick={() => handleSave('service')}
                       disabled={updateStatusMutation.isPending}
                       className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 flex items-center disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                       {updateStatusMutation.isPending ? 'Saving...' : (
                           <>
                               <Save className="h-4 w-4 mr-2" /> 
                               {alertData?.callStatus?.service?.remark ? 'Update' : 'Save & Complete'}
                           </>
                       )}
                    </button>
                 </div>
              </div>
           )}
        </div>
      </div>
    </div>
  );
}


