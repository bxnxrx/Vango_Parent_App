# Security Policy

## 🛡️ Data Privacy & Child Safety
As an academic project involving child transportation data, we take security seriously.

### Critical Guidelines
1.  **Personal Data:** Never commit real student names, addresses, or photos to the repository. Use **dummy data** (mock data) for testing and development.
2.  **Location Data:** Real-time GPS coordinates are sensitive. Ensure the WebSocket stream is authenticated via JWT.
3.  **Secrets:** Never commit API Keys (Google Maps, Firebase, Supabase) to GitHub. Use a `.env` file.

## 🐛 Reporting a Vulnerability
If you discover a security issue (e.g., exposed API keys, unauthorized data access), please report it immediately to the team lead or supervisor.

**DO NOT** create a public GitHub issue for security vulnerabilities.