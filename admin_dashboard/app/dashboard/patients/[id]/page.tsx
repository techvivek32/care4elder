import { notFound } from 'next/navigation';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';
import { 
  User, Phone, Mail, FileText, Calendar, Users, 
  Activity, CheckCircle, XCircle, Clock, HeartPulse 
} from 'lucide-react';
import Link from 'next/link';

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
