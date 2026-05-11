# TrustPrism

## Architecture Notes
TrustPrism is a full-stack application built with the following technologies:
- **Frontend**: React, Vite, TailwindCSS, React Router, Recharts, Socket.io-client.
- **Backend**: Node.js, Express.js, Knex (PostgreSQL), Socket.io.
- **Database**: PostgreSQL 15.
- **Infrastructure**: Containerized with Docker and Docker Compose.

## Environment Variables
The application requires the following environment variables. You will need to create a `.env` file in the root directory and another `.env` inside the `backend/` directory.

**Backend (`backend/.env`)**
- `PORT`: The port the backend server runs on (default: 5000)
- `DB_HOST`: Database host (e.g., `postgres` when running in Docker)
- `DB_USER`: Database user
- `DB_PASSWORD`: Database password
- `DB_NAME`: Database name
- `DB_PORT`: Database port (e.g., 5432)
- `JWT_SECRET`: Secret key for signing JSON Web Tokens

**Database (`.env` in root)**
- `POSTGRES_USER`: PostgreSQL user
- `POSTGRES_PASSWORD`: PostgreSQL password
- `POSTGRES_DB`: PostgreSQL database name

## Setup Steps
1. Clone the repository.
2. Setup environment variables as described above.
3. Start the application using Docker Compose:
   ```bash
   docker-compose up --build
   ```
4. Access the frontend at `http://localhost:5173` and the backend at `http://localhost:5000`.

## Deployment Instructions & Reliability
We follow a strict CI/CD pipeline and environment separation strategy to ensure deployment reliability and predictable deploys.

### Environments
We maintain three separate environments to ensure we never test directly in production:
- **Development (`dev` branch)**: For initial testing of new features.
- **Staging (`staging` branch)**: Mirrors production exactly. Used to catch disasters earlier and perform final QA.
- **Production (`main` branch)**: Live environment. 

### CI/CD Pipeline
On every push to the `dev`, `staging`, or `main` branches, our CI/CD pipeline (via GitHub Actions) automatically triggers the following steps:
1. **Lint**: Lints the codebase to enforce code quality and formatting.
2. **Test**: Runs automated tests to ensure nothing is broken.
3. **Build**: Builds the application assets for deployment.
4. **Deploy**: Deploys the built application to the corresponding environment **only if** all previous steps pass successfully.
