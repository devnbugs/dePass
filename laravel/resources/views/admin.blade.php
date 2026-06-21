<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{{ config('app.name', 'Laravel') }} Admin</title>
        <link rel="icon" type="image/svg+xml" href="{{ asset('brand/3d-cube-scan.svg') }}" />
        <link rel="icon" type="image/png" href="{{ asset('brand/3d-cube-scan.png') }}" />
        <link rel="apple-touch-icon" href="{{ asset('brand/3d-cube-scan.png') }}" />
        @fonts
        @vite(['resources/css/app.css', 'resources/js/app.jsx'])
        <meta http-equiv="refresh" content="0;url={{ route('admin.dashboard') }}" />
    </head>
    <body class="bg-[#FDFDFC] dark:bg-[#0a0a0a] text-[#1b1b18] min-h-screen">
        <div class="min-h-screen flex items-center justify-center">
            <p class="text-gray-500">Redirecting to <a href="{{ route('admin.dashboard') }}" class="text-[#FA3E2C] underline">admin dashboard</a>...</p>
        </div>
    </body>
</html>
