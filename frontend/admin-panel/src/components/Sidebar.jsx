import { NavLink } from 'react-router-dom';

const Sidebar = () => {
  const navItems = [
    { path: '/dashboard', label: 'Dashboard', icon: '📊' },
    {
      path: '/orders',
      label: 'Orders',
      icon: '📦',
      subItems: [
        { path: '/orders', label: 'All Orders' },
        { path: '/orders?status=ongoing', label: 'Ongoing' },
        { path: '/orders?status=review', label: 'For Review' },
      ],
    },
    { path: '/drivers', label: 'Drivers', icon: '🚗' },
    { path: '/customers', label: 'Customers', icon: '👥' },
  ];

  return (
    <aside className="w-64 bg-slate-800 text-white flex flex-col">
      <div className="p-4 border-b border-slate-700">
        <h1 className="text-xl font-bold">Logistics Admin</h1>
      </div>
      <nav className="flex-1 p-4 space-y-2">
        {navItems.map((item) => (
          <div key={item.path}>
            <NavLink
              to={item.path}
              className={({ isActive }) =>
                `flex items-center space-x-2 px-4 py-2 rounded-md hover:bg-slate-700 ${
                  isActive ? 'bg-slate-700' : ''
                }`
              }
            >
              <span>{item.icon}</span>
              <span>{item.label}</span>
            </NavLink>
          </div>
        ))}
      </nav>
    </aside>
  );
};

export default Sidebar;

