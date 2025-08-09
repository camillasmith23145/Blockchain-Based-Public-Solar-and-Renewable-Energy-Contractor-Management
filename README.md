# Blockchain-Based Public Solar and Renewable Energy Contractor Management

A comprehensive smart contract system built on the Stacks blockchain for managing renewable energy contractors, certifications, and installations. This system provides transparent, immutable records for solar installations, renewable energy systems, electrical interconnections, energy storage, and green building certifications.

## System Overview

This system consists of five interconnected smart contracts that work together to manage the entire renewable energy contractor ecosystem:

### 1. Solar Installer Certification Contract (`solar-installer-cert.clar`)
- Issues and manages permits for photovoltaic system installation companies
- Tracks installer qualifications, certifications, and performance history
- Manages permit applications, approvals, and renewals
- Maintains a registry of certified solar installers

### 2. Renewable Energy System Oversight Contract (`renewable-energy-oversight.clar`)
- Regulates installation of wind turbines and geothermal systems
- Manages environmental impact assessments
- Tracks system performance and compliance
- Handles permit applications for large-scale renewable projects

### 3. Electrical Interconnection Management Contract (`electrical-interconnection.clar`)
- Coordinates connection of renewable energy systems to the power grid
- Manages grid capacity and interconnection requests
- Tracks electrical safety compliance
- Handles utility coordination and approvals

### 4. Energy Storage System Regulation Contract (`energy-storage-regulation.clar`)
- Manages permits for battery storage and backup power systems
- Tracks storage system specifications and safety compliance
- Handles installation and maintenance records
- Manages grid-tied storage system approvals

### 5. Green Building Certification Contract (`green-building-cert.clar`)
- Verifies compliance with sustainable construction standards
- Issues green building certifications and ratings
- Tracks energy efficiency metrics
- Manages LEED and other certification processes

## Key Features

- **Transparent Permitting**: All permits and certifications are recorded on-chain
- **Contractor Verification**: Immutable records of contractor qualifications
- **Performance Tracking**: Historical data on installations and performance
- **Compliance Management**: Automated compliance checking and reporting
- **Public Registry**: Searchable database of certified contractors and systems
- **Audit Trail**: Complete history of all transactions and changes

## Data Structures

### Contractor Profile
- Principal address
- Company name and details
- Certification levels and types
- Performance ratings
- Active permits and projects

### Installation Records
- System specifications
- Installation date and contractor
- Performance metrics
- Compliance status
- Maintenance history

### Permit Management
- Application details
- Approval status and conditions
- Expiration dates
- Renewal history

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Stacks wallet for testing

### Installation

1. Clone the repository
2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

3. Run tests:
   \`\`\`bash
   npm test
   \`\`\`

4. Deploy contracts:
   \`\`\`bash
   clarinet deploy
   \`\`\`

## Testing

The system includes comprehensive tests using Vitest:

- Unit tests for each contract function
- Integration tests for cross-contract workflows
- Performance and gas optimization tests
- Security and access control tests

Run tests with:
\`\`\`bash
npm test
\`\`\`

## Contract Functions

### Public Functions
- `register-contractor`: Register a new contractor
- `apply-for-permit`: Submit permit application
- `approve-permit`: Approve pending permit (admin only)
- `update-installation`: Record installation details
- `renew-certification`: Renew contractor certification

### Read-Only Functions
- `get-contractor-info`: Retrieve contractor details
- `get-permit-status`: Check permit status
- `get-installation-history`: View installation records
- `is-certified-contractor`: Verify contractor certification

## Security Features

- Role-based access control
- Multi-signature requirements for critical operations
- Time-locked permit approvals
- Automated compliance checking
- Immutable audit trails

## Governance

The system includes governance mechanisms for:
- Updating certification requirements
- Modifying permit processes
- Adding new renewable energy technologies
- Adjusting compliance standards

## Future Enhancements

- Integration with IoT devices for real-time monitoring
- Automated performance-based incentives
- Cross-chain compatibility
- Mobile application for contractors
- API for third-party integrations

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License.
