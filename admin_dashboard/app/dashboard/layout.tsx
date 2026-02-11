'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LayoutDashboard, UserCheck, AlertTriangle, CreditCard, LogOut, Users, Inbox, Settings, Image as ImageIcon } from 'lucide-react';
import { signOut } from 'next-auth/react';
import clsx from 'clsx';

const navItems = [
  { name: 'Overview', href: '/dashboard', icon: LayoutDashboard },
  { name: 'New Requests', href: '/dashboard/requests', icon: Inbox },
  { name: 'Doctors', href: '/dashboard/doctors', icon: UserCheck },
  { name: 'Patients', href: '/dashboard/patients', icon: Users },
  { name: 'SOS Alerts', href: '/dashboard/sos', icon: AlertTriangle },
  { name: 'Payouts', href: '/dashboard/doctors/payouts', icon: CreditCard },
  { name: 'Hero Section', href: '/dashboard/hero-section', icon: ImageIcon },
  { name: 'Settings', href: '/dashboard/settings', icon: Settings },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <div className="flex h-screen bg-gray-100">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r">
        <div className="flex items-center justify-center h-16 border-b">
          <h1 className="text-xl font-bold text-blue-600">CareSafe Admin</h1>
        </div>
        <nav className="p-4 space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={clsx(
                  'flex items-center px-4 py-2 text-sm font-medium rounded-md group',
                  pathname === item.href
                    ? 'bg-blue-50 text-blue-600'
                    : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                )}
              >
                <Icon className="w-5 h-5 mr-3" />
                {item.name}
              </Link>
            );
          })}
        </nav>
        <div className="p-4 border-t">
          <button
            onClick={() => signOut()}
            className="flex items-center w-full px-4 py-2 text-sm font-medium text-red-600 rounded-md hover:bg-red-50"
          >
            <LogOut className="w-5 h-5 mr-3" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto p-8">
        {children}
      </main>
    </div>
  );
}
