import { useLocation, Link } from 'react-router-dom';

const Breadcrumbs = () => {
  const location = useLocation();
  const pathnames = location.pathname.split('/').filter((x) => x);

  const getBreadcrumbName = (name) => {
    const names = {
      orders: 'Orders',
      'place-order': 'Place Order',
    };
    return names[name] || name.charAt(0).toUpperCase() + name.slice(1);
  };

  return (
    <nav className="flex items-center space-x-2 text-sm text-slate-600 mb-6">
      <Link
        to="/place-order"
        className="hover:text-slate-900 transition font-medium"
      >
        Home
      </Link>
      {pathnames.map((name, index) => {
        const routeTo = `/${pathnames.slice(0, index + 1).join('/')}`;
        const isLast = index === pathnames.length - 1;
        return (
          <span key={routeTo} className="flex items-center space-x-2">
            <svg className="h-4 w-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
            {isLast ? (
              <span className="text-slate-900 font-medium">{getBreadcrumbName(name)}</span>
            ) : (
              <Link
                to={routeTo}
                className="hover:text-slate-900 transition font-medium"
              >
                {getBreadcrumbName(name)}
              </Link>
            )}
          </span>
        );
      })}
    </nav>
  );
};

export default Breadcrumbs;
