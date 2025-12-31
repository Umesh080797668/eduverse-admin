# Admin App

A Flutter application for managing teachers, students, and earnings in an attendance system.

## Features

- Admin login
- View all teachers
- View teacher-based students
- Check collected amounts/earnings
- Activate/deactivate teacher accounts

## Setup

1. Ensure Flutter is installed.
2. Run `flutter pub get` to install dependencies.
3. Update the backend URL in `lib/services/api_service.dart`.
4. Run `flutter run` to launch the app.

## Backend

This app connects to the backend at the specified URL. Ensure the backend provides the following endpoints:

- POST /api/admin/login
- GET /api/teachers
- GET /api/teachers/:id/students
- GET /api/teachers/:id/earnings
- POST /api/teachers/:id/activate
- POST /api/teachers/:id/deactivate
