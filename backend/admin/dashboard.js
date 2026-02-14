// Simple Admin Dashboard Logic
// In a real app, this would be a React/Vue app checking for a token
// and making API calls.

// Config
const API_URL = 'http://localhost:3000/api';

document.addEventListener('DOMContentLoaded', () => {
    // Mock check for token (replace with real auth logic)
    const token = localStorage.getItem('adminToken');
    if (!token) {
        // Redirect to login or show login form
        // For demo purposes, we'll assume we are authorized or show a mock message
        // console.log("No token found. Please login.");
    }

    // Navigation
    document.getElementById('nav-dashboard').addEventListener('click', loadDashboard);
    document.getElementById('nav-users').addEventListener('click', loadUsers);

    // Initial Load
    loadDashboard();
});

function loadDashboard() {
    const content = document.getElementById('content-area');
    content.innerHTML = `
        <h2>Dashboard</h2>
        <p>Welcome to the TANDAU Admin Panel.</p>
        <div class="row">
            <div class="col-md-4">
                <div class="card text-white bg-primary mb-3">
                    <div class="card-header">Total Users</div>
                    <div class="card-body">
                        <h5 class="card-title" id="total-users-count">Loading...</h5>
                    </div>
                </div>
            </div>
            <!-- More cards... -->
        </div>
    `;

    // Fetch stats
    // fetch(`${API_URL}/stats`).then(...)
}

function loadUsers() {
    const content = document.getElementById('content-area');
    content.innerHTML = `
        <h2>Users Management</h2>
        <div class="table-responsive">
            <table class="table table-striped table-sm">
                <thead>
                    <tr>
                        <th>UID</th>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="users-table-body">
                    <tr><td colspan="5">Loading users...</td></tr>
                </tbody>
            </table>
        </div>
    `;

    // Fetch users (this requires a valid token with admin role)
    // fetch(`${API_URL}/users`, { headers: { Authorization: `Bearer ${token}` } }) ...
    // Mock Data for display
    const mockUsers = [
        { uid: '123', displayName: 'Admin User', email: 'admin@tandau.com', role: 'admin' },
        { uid: '456', displayName: 'Student One', email: 'student@test.com', role: 'user' }
    ];
    renderUsersTable(mockUsers);
}

function renderUsersTable(users) {
    const tbody = document.getElementById('users-table-body');
    tbody.innerHTML = '';
    users.forEach(user => {
        tbody.innerHTML += `
            <tr>
                <td>${user.uid}</td>
                <td>${user.displayName}</td>
                <td>${user.email}</td>
                <td>${user.role}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary">Edit</button>
                    <button class="btn btn-sm btn-outline-danger">Delete</button>
                </td>
            </tr>
        `;
    });
}
