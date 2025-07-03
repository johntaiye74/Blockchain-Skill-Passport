# 🎓 Blockchain Skill Passport

A decentralized skill verification system built on Stacks blockchain that allows users to create verifiable portfolios of their skills from bootcamps, MOOCs, and employers.

## 🌟 Features

- 📋 **Create Skill Passport**: Users can create their own skill portfolio
- 🏢 **Verified Issuers**: Bootcamps, educational institutions, and employers can become verified skill issuers
- ✅ **Issue Verified Skills**: Verified issuers can award skills to users with blockchain verification
- 📝 **Self-Reported Skills**: Users can add their own skills (marked as unverified)
- 🔍 **Skill Lookup**: Query skills by user, category, and verification status
- 📊 **Portfolio Analytics**: View total skills and verified skill counts

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
clarinet new skill-passport-project
cd skill-passport-project
```

Copy the contract code into `contracts/skill-passport.clar`

### Testing

```bash
clarinet test
```

### Deployment

```bash
clarinet deploy
```

## 📖 Usage

### For Users

#### 1. Create Your Skill Passport
```clarity
(contract-call? .skill-passport create-passport)
```

#### 2. Add Self-Reported Skills
```clarity
(contract-call? .skill-passport self-report-skill 
  "JavaScript" 
  "Programming" 
  "Intermediate" 
  "3 years of experience building web applications")
```

#### 3. View Your Passport
```clarity
(contract-call? .skill-passport get-passport 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### For Educational Institutions/Employers

#### 1. Register as Verified Issuer (Contract Owner Only)
```clarity
(contract-call? .skill-passport add-verified-issuer 
  'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
  "Lambda School" 
  "Bootcamp")
```

#### 2. Issue Verified Skills to Students/Employees
```clarity
(contract-call? .skill-passport issue-skill 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  "Full Stack Development" 
  "Programming" 
  "Advanced" 
  "Completed 6-month intensive bootcamp program")
```

## 🔧 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `create-passport` | Create a new skill passport | None |
| `register-issuer` | Register yourself as issuer (owner only) | name, issuer-type |
| `add-verified-issuer` | Add verified issuer (owner only) | issuer, name, issuer-type |
| `issue-skill` | Issue verified skill to user | recipient, skill-name, category, level, description |
| `self-report-skill` | Add self-reported skill | skill-name, category, level, description |

### Read-Only Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `get-passport` | Get user's passport info | user |
| `get-skill` | Get specific skill details | user, skill-id |
| `get-issuer-info` | Get issuer information | issuer |
| `get-user-skill-count` | Get total skills for user | user |
| `is-verified-issuer` | Check if issuer is verified | issuer |
| `count-verified-skills` | Count verified skills for user | user |

## 🏗️ Data Structure

### Skill Passport
- `total-skills`: Number of skills in passport
- `created-at`: Block height when created
- `updated-at`: Block height of last update

### Skill Entry
- `skill-name`: Name of the skill
- `category`: Skill category (e.g., "Programming", "Design")
- `level`: Proficiency level (e.g., "Beginner", "Intermediate", "Advanced")
- `issuer`: Principal who issued the skill
- `issuer-name`: Display name of issuer
- `issued-at`: Block height when issued
- `verified`: Boolean indicating if skill is verified
- `description`: Detailed description of the skill

### Verified Issuer
- `name`: Display name of the issuer
- `issuer-type`: Type of issuer (e.g., "Bootcamp", "University", "Company")
- `verified-at`: Block height when verified
- `active`: Boolean indicating if issuer is active

## 🛡️ Security Features

- ✅ Only contract owner can add verified issuers
- ✅ Only verified issuers can issue verified skills
- ✅ Input validation for all parameters
- ✅ Duplicate passport prevention
- ✅ Immutable skill records on blockchain

## 🎯 Use Cases

- 🎓 **Bootcamp Graduates**: Showcase verified skills from coding bootcamps
- 🏢 **Job Seekers**: Present verifiable skill portfolio to employers
- 📚 **MOOC Learners**: Collect verified certificates from online courses
- 💼 **Professionals**: Build comprehensive skill profile across career
- 🏛️ **Institutions**: Issue tamper-proof skill certifications

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)
