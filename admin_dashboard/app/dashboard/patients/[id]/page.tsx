import { notFound } from 'next/navigation';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';
import { 
  User, Phone, Mail, FileText, Calendar, Users, 
  Activity, CheckCircle, XCircle, Clock, HeartPulse, 
  Stethoscope, Pill, Microscope, ClipboardList, Download
} from 'lucide-react';
import Link from 'next/link';

function calculateAge(dob: string | Date | undefined) {
  if (!dob) return null;
  const birthDate = new Date(dob);
  const today = new Date();
  let age = today.getFullYear() - birthDate.getFullYear();
  const m = today.getMonth() - birthDate.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }
  return age;
}

async function getPatient(id: string) {
  await dbConnect();
  try {
    const patient = await Patient.findById(id).lean();
    if (!patient) return null;
    return JSON.parse(JSON.stringify(patient));
  } catch (error) {
    console.error('Error fetching patient:', error);
    return null;
  }
}

export default async function PatientDetailsPage(props: { params: Promise<{ id: string }> }) {
  const params = await props.params;
  const patient = await getPatient(params.id);

  if (!patient) {
    notFound();
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Patient Details</h1>
        <Link 
          href="/dashboard/patients"
          className="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 transition-colors"
        >
          Back to List
        </Link>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Info Card */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white shadow rounded-lg p-6">
            <div className="flex items-start justify-between mb-6">
              <div className="flex items-center space-x-4">
                <div className="bg-blue-100 p-3 rounded-full">
                  <User className="w-8 h-8 text-blue-600" />
                </div>
                <div>
                  <h2 className="text-xl font-bold text-gray-900">{patient.name}</h2>
                  <p className="text-gray-500">Patient ID: {patient._id}</p>
                </div>
              </div>
              <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
                patient.isRelativeVerified ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
              }`}>
                {patient.isRelativeVerified ? (
                  <>
                    <CheckCircle className="w-4 h-4 mr-2" /> Verified
                  </>
                ) : (
                  <>
                    <Clock className="w-4 h-4 mr-2" /> Unverified
                  </>
                )}
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-1">
                <label className="text-sm font-medium text-gray-500">Email</label>
                <div className="flex items-center text-gray-900">
                  <Mail className="w-4 h-4 mr-2 text-gray-400" />
                  {patient.email}
                </div>
              </div>
              <div className="space-y-1">
                <label className="text-sm font-medium text-gray-500">Phone</label>
                <div className="flex items-center text-gray-900">
                  <Phone className="w-4 h-4 mr-2 text-gray-400" />
                  {patient.phone}
                </div>
              </div>
            </div>

            {/* Patient Medical Information (New Section) */}
            <div className="mt-8 border-t pt-6">
              <h3 className="text-lg font-medium text-gray-900 mb-6 flex items-center">
                <Stethoscope className="w-6 h-6 mr-2 text-blue-500" />
                Patient Medical Information Summary
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                <div className="bg-blue-50 p-4 rounded-xl border border-blue-100">
                  <span className="text-xs font-semibold text-blue-600 uppercase tracking-wider block mb-1">Age</span>
                  <span className="text-xl font-bold text-gray-900">{calculateAge(patient.dateOfBirth) ?? '—'} yrs</span>
                </div>
                <div className="bg-purple-50 p-4 rounded-xl border border-purple-100">
                  <span className="text-xs font-semibold text-purple-600 uppercase tracking-wider block mb-1">Gender</span>
                  <span className="text-xl font-bold text-gray-900">{patient.gender || '—'}</span>
                </div>
                <div className="bg-red-50 p-4 rounded-xl border border-red-100">
                  <span className="text-xs font-semibold text-red-600 uppercase tracking-wider block mb-1">Blood Group</span>
                  <span className="text-xl font-bold text-gray-900">{patient.bloodGroup || '—'}</span>
                </div>
                <div className="bg-green-50 p-4 rounded-xl border border-green-100">
                  <span className="text-xs font-semibold text-green-600 uppercase tracking-wider block mb-1">Wallet</span>
                  <span className="text-xl font-bold text-gray-900">₹{patient.walletBalance?.toFixed(2) || '0.00'}</span>
                </div>
              </div>

              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="p-5 border border-gray-100 rounded-2xl bg-white shadow-sm hover:shadow-md transition-shadow">
                    <h4 className="font-bold text-gray-900 mb-4 flex items-center text-sm uppercase tracking-tight">
                      <Activity className="w-4 h-4 mr-2 text-orange-500" />
                      Allergies & Sensitivities
                    </h4>
                    <div className={`p-3 rounded-lg text-sm ${patient.allergies ? 'bg-orange-50 text-orange-800' : 'bg-gray-50 text-gray-500 italic'}`}>
                      {patient.allergies || 'No allergies reported by the patient.'}
                    </div>
                  </div>

                  <div className="p-5 border border-gray-100 rounded-2xl bg-white shadow-sm hover:shadow-md transition-shadow">
                    <h4 className="font-bold text-gray-900 mb-4 flex items-center text-sm uppercase tracking-tight">
                      <Calendar className="w-4 h-4 mr-2 text-blue-500" />
                      Birth & Location
                    </h4>
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-500">Date of Birth:</span>
                        <span className="font-medium text-gray-900">{patient.dateOfBirth ? new Date(patient.dateOfBirth).toLocaleDateString('en-IN', { day: '2-digit', month: 'long', year: 'numeric' }) : '—'}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-500">Location:</span>
                        <span className="font-medium text-gray-900">{patient.location || '—'}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="p-5 border border-gray-100 rounded-2xl bg-white shadow-sm hover:shadow-md transition-shadow">
                    <h4 className="font-bold text-gray-900 mb-4 flex items-center text-sm uppercase tracking-tight">
                      <ClipboardList className="w-4 h-4 mr-2 text-purple-500" />
                      Past Surgical History
                    </h4>
                    {patient.pastSurgeries && patient.pastSurgeries.length > 0 ? (
                      <div className="space-y-3">
                        {patient.pastSurgeries.map((s: any, i: number) => (
                          <div key={i} className="flex items-center justify-between p-3 bg-gray-50 rounded-xl border border-gray-100">
                            <div>
                              <div className="font-bold text-sm text-gray-900">{s.procedure}</div>
                              {s.date && <div className="text-xs text-gray-500 mt-0.5">{new Date(s.date).toLocaleDateString()}</div>}
                            </div>
                            {s.documentUrl && (
                              <a href={s.documentUrl} target="_blank" className="p-2 bg-white text-blue-600 hover:text-blue-700 rounded-full shadow-sm border border-gray-100 transition-all">
                                <Download className="w-4 h-4" />
                              </a>
                            )}
                          </div>
                        ))}
                      </div>
                    ) : <div className="text-center py-4 bg-gray-50 rounded-xl text-sm text-gray-400 italic border border-dashed border-gray-200">No surgical history available.</div>}
                  </div>

                  <div className="p-5 border border-gray-100 rounded-2xl bg-white shadow-sm hover:shadow-md transition-shadow">
                    <h4 className="font-bold text-gray-900 mb-4 flex items-center text-sm uppercase tracking-tight">
                      <Pill className="w-4 h-4 mr-2 text-green-500" />
                      Active Medications
                    </h4>
                    {patient.currentMedications && patient.currentMedications.length > 0 ? (
                      <div className="space-y-2">
                        {patient.currentMedications.map((m: any, i: number) => (
                          <div key={i} className="p-3 bg-gray-50 rounded-xl border border-gray-100">
                            <div className="font-bold text-sm text-gray-900">{m.name}</div>
                            {m.purpose && <div className="text-xs text-gray-600 mt-1 flex items-center">
                              <span className="w-1 h-1 bg-gray-400 rounded-full mr-2"></span>
                              {m.purpose}
                            </div>}
                          </div>
                        ))}
                      </div>
                    ) : <div className="text-center py-4 bg-gray-50 rounded-xl text-sm text-gray-400 italic border border-dashed border-gray-200">No active medications listed.</div>}
                  </div>
                </div>

                <div className="p-5 border border-gray-100 rounded-2xl bg-white shadow-sm hover:shadow-md transition-shadow">
                  <h4 className="font-bold text-gray-900 mb-4 flex items-center text-sm uppercase tracking-tight">
                    <Microscope className="w-4 h-4 mr-2 text-indigo-500" />
                    Laboratory & Diagnostic Reports
                  </h4>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                    <div className="space-y-3">
                      <span className="text-xs font-bold text-gray-400 uppercase tracking-widest block">Lab Reports</span>
                      {patient.labReports && patient.labReports.length > 0 ? (
                        <div className="grid grid-cols-1 gap-2">
                          {patient.labReports.map((url: string, i: number) => (
                            <a key={i} href={url} target="_blank" className="flex items-center justify-between p-3 bg-indigo-50 text-indigo-700 rounded-xl text-xs border border-indigo-100 hover:bg-indigo-100 transition-colors">
                              <div className="flex items-center font-bold">
                                <FileText className="w-4 h-4 mr-2" />
                                LAB REPORT #{i + 1}
                              </div>
                              <Download className="w-4 h-4" />
                            </a>
                          ))}
                        </div>
                      ) : <span className="text-xs text-gray-400 italic bg-gray-50 p-3 rounded-xl block text-center">No lab reports uploaded.</span>}
                    </div>
                    <div className="space-y-3">
                      <span className="text-xs font-bold text-gray-400 uppercase tracking-widest block">Medical Prescriptions</span>
                      {patient.prescriptions && patient.prescriptions.length > 0 ? (
                        <div className="grid grid-cols-1 gap-2">
                          {patient.prescriptions.map((url: string, i: number) => (
                            <a key={i} href={url} target="_blank" className="flex items-center justify-between p-3 bg-green-50 text-green-700 rounded-xl text-xs border border-green-100 hover:bg-green-100 transition-colors">
                              <div className="flex items-center font-bold">
                                <FileText className="w-4 h-4 mr-2" />
                                PRESCRIPTION #{i + 1}
                              </div>
                              <Download className="w-4 h-4" />
                            </a>
                          ))}
                        </div>
                      ) : <span className="text-xs text-gray-400 italic bg-gray-50 p-3 rounded-xl block text-center">No prescriptions uploaded.</span>}
                    </div>
                  </div>
                </div>

                {/* Additional Info & Documents */}
                <div className="p-5 border border-gray-100 rounded-2xl bg-white shadow-sm hover:shadow-md transition-shadow">
                  <h4 className="font-bold text-gray-900 mb-4 flex items-center text-sm uppercase tracking-tight">
                    <FileText className="w-4 h-4 mr-2 text-blue-500" />
                    Additional Patient Context
                  </h4>
                  <div className="bg-gray-50 p-4 rounded-xl text-sm text-gray-700 mb-6 border border-gray-100 leading-relaxed">
                    {patient.additionalInfo || 'No additional clinical context provided by the patient.'}
                  </div>
                  
                  <span className="text-xs font-bold text-gray-400 uppercase tracking-widest block mb-3">Other Supporting Documents</span>
                  {patient.additionalDocuments && patient.additionalDocuments.length > 0 ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                      {patient.additionalDocuments.map((url: string, i: number) => (
                        <a key={i} href={url} target="_blank" className="flex items-center justify-between p-3 bg-blue-50 text-blue-700 rounded-xl text-xs border border-blue-100 hover:bg-blue-100 transition-colors">
                          <div className="flex items-center font-bold">
                            <FileText className="w-4 h-4 mr-2" />
                            DOC #{i + 1}
                          </div>
                          <Download className="w-4 h-4" />
                        </a>
                      ))}
                    </div>
                  ) : <span className="text-xs text-gray-400 italic bg-gray-50 p-3 rounded-xl block text-center">No additional supporting documents.</span>}
                </div>
              </div>
            </div>

            {/* Medical History */}
            <div className="mt-8 border-t pt-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
                <HeartPulse className="w-5 h-5 mr-2 text-red-500" />
                Medical History
              </h3>
              {Object.keys(patient.medicalHistory || {}).length > 0 ? (
                 <div className="bg-gray-50 rounded-lg p-4">
                    <pre className="whitespace-pre-wrap text-sm text-gray-700 font-sans">
                      {JSON.stringify(patient.medicalHistory, null, 2)}
                    </pre>
                 </div>
              ) : (
                <p className="text-gray-500 italic">No medical history recorded.</p>
              )}
            </div>
          </div>

          {/* Documents/Images Section (if any in future, for now placeholder if schema has none) */}
          {/* Note: Patient schema currently doesn't have a specific documents array like Doctor, 
              but if added later, this is where it would go. */}
        </div>

        {/* Sidebar Info */}
        <div className="space-y-6">
          {/* Emergency Contacts */}
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
              <Users className="w-5 h-5 mr-2 text-orange-500" />
              Emergency Contacts
            </h3>
            {patient.emergencyContacts && patient.emergencyContacts.length > 0 ? (
              <div className="space-y-4">
                {patient.emergencyContacts.map((contact: any, index: number) => (
                  <div key={index} className="flex flex-col p-3 border rounded-lg bg-gray-50">
                    <span className="font-medium text-gray-900">{contact.name}</span>
                    <span className="text-sm text-gray-500 mb-1">{contact.relation}</span>
                    <div className="flex items-center text-sm text-gray-700 mt-1">
                      <Phone className="w-3 h-3 mr-1 text-gray-400" />
                      {contact.phone}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500 text-sm italic">No emergency contacts listed.</p>
            )}
          </div>

          {/* System Info */}
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
              <Activity className="w-5 h-5 mr-2 text-purple-500" />
              System Info
            </h3>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-500">Joined Date</span>
                <span className="text-gray-900">
                  {new Date(patient.createdAt).toLocaleDateString()}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Last Updated</span>
                <span className="text-gray-900">
                  {new Date(patient.updatedAt).toLocaleDateString()}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-500">Email Verified</span>
                {patient.isEmailVerified ? (
                  <CheckCircle className="w-4 h-4 text-green-500" />
                ) : (
                  <XCircle className="w-4 h-4 text-red-500" />
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
