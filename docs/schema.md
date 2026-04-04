# Neospartan Data Schema (Firestore)

This schema is designed to support the **Agoge AI Engine** (DOM-RL) while maintaining a lightweight, document-based structure in Firebase.

## Collections

### 1. `users`
Profiles and global training settings.
- `id`: string (Firebase Auth UID)
- `displayName`: string
- `philosophicalBaseline`: string (e.g., "Marcus Aurelius", "Seneca")
- `experienceLevel`: enum (Novice, Hoplite, Spartan)
- `lastReadinessScore`: number (0-100)
- `createdAt`: timestamp

### 2. `workouts`
Logged training sessions.
- `id`: string
- `userId`: string (index)
- `type`: enum (Stadion, Phalanx, Agoge-Generated)
- `date`: timestamp
- `totalVolume`: number
- `averageRPE`: number
- `exercises`: array
    - `exerciseId`: string
    - `name`: string
    - `sets`: array
        - `reps`: number
        - `weight`: number
        - `rpe`: number

### 3. `biometrics`
Synchronized data from Google Health Connect.
- `id`: string
- `userId`: string (index)
- `type`: enum (HRV, Sleep, RHR, Steps)
- `value`: number
- `unit`: string
- `timestamp`: timestamp

### 4. `library`
Vetted exercise catalogue.
- `id`: string
- `name`: string
- `category`: string (Plyometric, Isometric, Combat)
- `youtubeId`: string
- `instructions`: string
- `targetMetaphor`: string (e.g., "The Shield of Archidamus")

## Design Rationale
- **Denormalization**: Exercise names are stored directly in `workouts` to avoid excessive joins during real-time recommendation.
- **Indexing**: `userId` is indexed across all collections to ensure sub-millisecond retrieval for the on-device inference engine.
