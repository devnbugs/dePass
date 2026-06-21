<?php

namespace App\Providers;

use App\Models\Device;
use App\Models\Event;
use App\Models\Organization;
use App\Models\Pass;
use App\Models\PassTemplate;
use App\Models\PassType;
use App\Models\Scan;
use App\Models\SystemConfiguration;
use App\Models\User;
use App\Observers\AuditLogObserver;
use App\Policies\AdminPolicy;
use App\Policies\DevicePolicy;
use App\Policies\EventPolicy;
use App\Policies\ScanPolicy;
use App\Policies\UserPolicy;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(Event::class, EventPolicy::class);
        Gate::policy(User::class, UserPolicy::class);
        Gate::policy(Device::class, DevicePolicy::class);

        Gate::define('access-admin', [AdminPolicy::class, 'accessAdmin']);
        Gate::policy(Scan::class, ScanPolicy::class);

        Event::observe(AuditLogObserver::class);
        Pass::observe(AuditLogObserver::class);
        PassType::observe(AuditLogObserver::class);
        Device::observe(AuditLogObserver::class);
        User::observe(AuditLogObserver::class);
        Organization::observe(AuditLogObserver::class);
        PassTemplate::observe(AuditLogObserver::class);
        SystemConfiguration::observe(AuditLogObserver::class);
    }
}
