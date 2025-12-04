import { Outlet, useLocation } from 'react-router-dom';
import Header from './Header';
import Breadcrumbs from './Breadcrumbs';

const Layout = () => {
  const location = useLocation();
  const isPlaceOrderPage = location.pathname === '/place-order' || location.pathname === '/';

  return (
    <div className="min-h-screen bg-slate-50">
      <Header />
      {!isPlaceOrderPage && (
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
          <Breadcrumbs />
        </div>
      )}
      <main className={isPlaceOrderPage ? '' : 'mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pb-8'}>
        <Outlet />
      </main>
    </div>
  );
};

export default Layout;
