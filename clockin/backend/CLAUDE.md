# CLAUDE.md — NestJS API Template

## Project Overview

<!-- Replace with a 2–3 sentence description of this project: what it does, who uses it. -->

## Stack

- **Framework**: NestJS + TypeScript (strict mode)
- **Database**: PostgreSQL + TypeORM
- **Validation**: class-validator + class-transformer
- **Auth**: JWT via @nestjs/passport
- **Testing**: Jest

---

## Project Structure

```
src/
├── main.ts                         # Bootstrap — global pipes, filters, interceptors
├── app.module.ts                   # Root module — imports all feature and core modules
├── config/
│   ├── env.validation.ts           # Joi env schema
│   └── database.config.ts          # TypeORM config factory
├── database/
│   ├── database.module.ts          # TypeOrmModule.forRootAsync()
│   └── migrations/                 # TypeORM migration files
├── common/
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   ├── pipes/
│   ├── types/
│   └── utils/
└── modules/
    └── <feature>/
        ├── <feature>.module.ts
        ├── <feature>.controller.ts
        ├── <feature>.service.ts
        ├── <feature>.repository.ts
        ├── dto/
        └── entities/
```

---

## Behavior Rules

### Feature Requests

- When asked to build or implement a feature, **always invoke the `orchestrator` agent**
- Never write code directly for a new feature — the pipeline must run first
- Only write code outside the pipeline for quick fixes, config changes, or one-liners explicitly asked for

### File Naming Conventions

- Use `kebab-case` for all file and folder names (e.g., `user-profile.service.ts`)
- Follow NestJS suffix conventions:
  - Modules: `<name>.module.ts`
  - Controllers: `<name>.controller.ts`
  - Services: `<name>.service.ts`
  - DTOs: `<name>.dto.ts` (e.g., `create-user.dto.ts`, `update-user.dto.ts`)
  - Entities: `<name>.entity.ts`
  - Guards: `<name>.guard.ts`
  - Interceptors: `<name>.interceptor.ts`
  - Filters: `<name>.filter.ts`
  - Pipes: `<name>.pipe.ts`
  - Decorators: `<name>.decorator.ts`
- Class names use `PascalCase` (e.g., `UserProfileService`)
- Variables and methods use `camelCase` (e.g., `getUserById`)
- Database column names use `snake_case` (e.g., `date_created`)
- Constants use `UPPER_SNAKE_CASE` (e.g., `JWT_SECRET`)

### Code Style

- Always use `async/await` — never `.then()`
- Never use `any` — use typed interfaces, generics, or `unknown`
- Always define explicit return types on service and controller methods
- Keep services under 200 lines — split into smaller services if larger
- Use `readonly` on injected dependencies in constructors

### Module Structure

Every feature module must follow this exact structure:

```
src/modules/<name>/
├── <name>.module.ts
├── <name>.controller.ts
├── <name>.service.ts
├── <name>.repository.ts
├── dto/
│   ├── create-<name>.dto.ts
│   └── update-<name>.dto.ts
└── entities/
    └── <name>.entity.ts
```

- Register every new module in `app.module.ts`
- Use constructor-based dependency injection always
- DTOs must use `class-validator` decorators on every field
- Services never import `Repository<Entity>` directly — use the repository file

### Common Folder

Shared code that is reused across modules lives in `src/common/` — never duplicate it inside a feature module.

```
src/common/
├── decorators/        # Custom parameter and method decorators
├── filters/           # Global exception filters
├── guards/            # Auth and role guards
├── interceptors/      # Logging, response transform interceptors
├── pipes/             # Custom validation pipes
├── types/             # Shared TypeScript interfaces and types
└── utils/             # Pure helper functions
```

- If logic is used by more than one module, it belongs in `src/common/`
- Register global filters, pipes, guards, and interceptors in `main.ts` — not in individual modules
- Never put business logic in `src/common/` — utilities and infrastructure only
- Types shared across modules go in `src/common/types/<name>.type.ts`

### Database Connection

TypeORM connection setup lives outside feature modules:

```
src/
├── config/
│   ├── env.validation.ts       # Joi schema — validates all env vars at startup
│   └── database.config.ts      # TypeORM config factory using ConfigService
└── database/
    └── database.module.ts      # Registers TypeOrmModule.forRootAsync()
```

- `database.config.ts` reads DB credentials via `ConfigService` — never `process.env` directly
- `database.module.ts` is imported once in `app.module.ts` — never in feature modules
- `synchronize` must be `false` in all environments — use migrations only
- Entity auto-discovery uses glob: `__dirname + '/../**/*.entity{.ts,.js}'`

### Migrations

- Migration files live in `src/database/migrations/`
- Never use `synchronize: true` — always generate and run migrations explicitly
- Generate a migration: `npm run migration:generate -- src/database/migrations/<name>`
- Run migrations: `npm run migration:run`
- Revert last migration: `npm run migration:revert`
- Migration filenames are auto-timestamped — never rename them

### Database Queries

- All DB queries live in `<name>.repository.ts` — never in the service
- Use TypeORM `QueryBuilder` for complex queries
- Entity column names use `snake_case`, TypeScript properties use `camelCase`

### Environment Variables

- Never read `process.env` directly — always inject `ConfigService`
- All env vars must be validated at startup via Joi schema in `src/config/`

### API Response Format

All endpoints must return a consistent response shape:

**Success:**

```json
{
  "success": true,
  "data": {},
  "message": "optional message"
}
```

**Success (paginated):**

```json
{
  "success": true,
  "data": [],
  "meta": {
    "total": 50,
    "page": 1,
    "limit": 10,
    "totalPages": 5,
    "hasPreviousPage": false,
    "hasNextPage": true
  },
  "message": "optional message"
}
```

**Error:**

```json
{
  "success": false,
  "statusCode": 400,
  "message": "error description",
  "errors": []
}
```

- Use a global response interceptor in `src/common/interceptors/` to wrap all success responses
- Use a global exception filter in `src/common/filters/` to format all error responses
- Never return raw TypeORM entities — always map to a DTO or plain object

### main.ts Setup

Global registrations belong in `main.ts` — not in individual modules:

```ts
app.useGlobalPipes(
  new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }),
);
app.useGlobalFilters(new HttpExceptionFilter());
app.useGlobalInterceptors(new ResponseInterceptor());
```

- `whitelist: true` — strips properties not in the DTO
- `forbidNonWhitelisted: true` — throws error if unknown properties are sent
- Always enable Swagger in non-production environments only

### Error Handling

- Throw NestJS built-in exceptions only (`NotFoundException`, `BadRequestException`, etc.)
- Never throw raw `Error` objects from services or controllers

### Testing

**File placement:**

- Unit test files are co-located next to the source file they test — never in a separate folder
- Name: `<name>.spec.ts` placed in the same directory as the source file
- E2E tests are the only exception — they go in `test/` at the project root

```
src/modules/users/
├── users.controller.ts
├── users.controller.spec.ts     ← co-located
├── users.service.ts
├── users.service.spec.ts        ← co-located
├── users.repository.ts
└── users.repository.spec.ts     ← co-located

test/
└── app.e2e-spec.ts              ← E2E only
```

**Rules:**

- Every service, controller, and repository must have a `.spec.ts` file
- All repositories and external dependencies must be mocked — no real DB calls in unit tests
- Use `@nestjs/testing` and `Test.createTestingModule()` for all unit tests
- Every test must have a clear `describe` block per class and `it` block per method/case
- Cover happy paths, edge cases, and expected error throws
- Never use `any` in test files — type all mocks explicitly

---

## Agents

Located in `.claude/agents/`:

| Agent            | Responsibility                                   |
| ---------------- | ------------------------------------------------ |
| `orchestrator`   | Runs the full pipeline end-to-end                |
| `planner`        | Breaks feature into tasks and file paths         |
| `plan-reviewer`  | Validates the plan before coding starts          |
| `coder`          | Implements code from an approved plan            |
| `coder-reviewer` | Reviews code for quality and correctness         |
| `tester`         | Generates Jest unit tests                        |
| `security`       | Audits code for OWASP Top 10 and vulnerabilities |

---

## What NOT to Do

- Do not skip the orchestrator for feature work
- Do not use `any` under any circumstance
- Do not read `process.env` outside of config files
- Do not put DB queries in services
- Do not write files to disk if the security agent returns `fail`