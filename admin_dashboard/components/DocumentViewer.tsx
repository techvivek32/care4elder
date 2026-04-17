'use client';

import { useState } from 'react';
import { Eye, Download, X, FileText } from 'lucide-react';

function resolveImageUrl(url: string) {
  if (!url) return '';
  if (url.startsWith('http')) return url;
  const cleanUrl = url.startsWith('/') ? url : `/${url}`;
  if (!cleanUrl.startsWith('/uploads/')) return `/uploads${cleanUrl}`;
  return cleanUrl;
}

export default function DocumentViewer({ documents }: { documents: string[] }) {
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  if (!documents || documents.length === 0) {
    return <p className="text-gray-500 italic">No documents uploaded.</p>;
  }

  const isPdf = (url: string) => url.toLowerCase().includes('.pdf');

  return (
    <>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
        {documents.map((doc: string, index: number) => {
          const url = resolveImageUrl(doc);
          return (
            <div key={index} className="space-y-2">
              <div className="flex items-center justify-between">
                <p className="text-sm font-medium text-gray-700">Document {index + 1}</p>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => setPreviewUrl(url)}
                    className="inline-flex items-center px-2 py-1 text-xs text-blue-600 hover:text-blue-800 border border-blue-200 rounded hover:bg-blue-50"
                  >
                    <Eye className="w-3 h-3 mr-1" /> View
                  </button>
                  <a
                    href={url}
                    download
                    className="inline-flex items-center px-2 py-1 text-xs text-green-600 hover:text-green-800 border border-green-200 rounded hover:bg-green-50"
                  >
                    <Download className="w-3 h-3 mr-1" /> Download
                  </a>
                </div>
              </div>
              <div
                className="border rounded-lg overflow-hidden bg-gray-50 p-2 cursor-pointer hover:opacity-90"
                onClick={() => setPreviewUrl(url)}
              >
                {isPdf(doc) ? (
                  <div className="flex flex-col items-center justify-center h-32 text-gray-400">
                    <FileText className="w-10 h-10 mb-2" />
                    <span className="text-xs">PDF Document</span>
                  </div>
                ) : (
                  <img
                    src={url}
                    alt={`Document ${index + 1}`}
                    className="w-full h-auto object-contain max-h-[200px]"
                  />
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Popup Modal */}
      {previewUrl && (
        <div className="fixed inset-0 bg-black bg-opacity-80 z-50 flex items-center justify-center p-4">
          <div className="relative bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] flex flex-col">
            {/* Header */}
            <div className="flex items-center justify-between px-4 py-3 border-b">
              <span className="font-semibold text-gray-800">Document Preview</span>
              <div className="flex items-center space-x-2">
                <a
                  href={previewUrl}
                  download
                  className="inline-flex items-center px-3 py-1.5 text-sm text-white bg-green-600 hover:bg-green-700 rounded"
                >
                  <Download className="w-4 h-4 mr-1" /> Download
                </a>
                <button
                  onClick={() => setPreviewUrl(null)}
                  className="p-1.5 text-gray-500 hover:text-gray-800 hover:bg-gray-100 rounded"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>
            {/* Content */}
            <div className="overflow-auto flex-1 p-4 flex items-center justify-center bg-gray-50">
              {isPdf(previewUrl) ? (
                <iframe
                  src={previewUrl}
                  className="w-full h-[75vh]"
                  title="Document Preview"
                />
              ) : (
                <img
                  src={previewUrl}
                  alt="Document Preview"
                  className="max-w-full max-h-[75vh] object-contain"
                />
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
