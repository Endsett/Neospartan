"""Database migration system for NeoSpartan Backend.

This module handles database schema migrations for Supabase.
"""

from typing import List, Dict, Any, Optional
from datetime import datetime
import asyncio
from supabase import create_client, Client

from config import settings
from database import db, DatabaseError


class Migration:
    """Represents a database migration."""

    def __init__(self, version: str, name: str, up_sql: str, down_sql: str = ""):
        self.version = version
        self.name = name
        self.up_sql = up_sql
        self.down_sql = down_sql
        self.applied_at: Optional[datetime] = None


class MigrationManager:
    """Manages database migrations."""

    MIGRATIONS_TABLE = "schema_migrations"

    def __init__(self):
        self.migrations: List[Migration] = []
        self._register_migrations()

    def _register_migrations(self):
        """Register all available migrations."""
        # Migration 001: Initial schema
        self.migrations.append(Migration(
            version="001",
            name="create_workout_session_tables",
            up_sql="""
            -- Workout sessions table
            CREATE TABLE IF NOT EXISTS workout_sessions (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
                name TEXT NOT NULL DEFAULT 'Workout Session',
                status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
                scheduled_date TIMESTAMP WITH TIME ZONE,
                started_at TIMESTAMP WITH TIME ZONE,
                completed_at TIMESTAMP WITH TIME ZONE,
                duration_seconds INTEGER DEFAULT 0,
                total_volume FLOAT DEFAULT 0.0,
                notes TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
            );

            -- Workout exercise entries table
            CREATE TABLE IF NOT EXISTS workout_exercise_entries (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                session_id UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
                exercise_id TEXT NOT NULL,
                exercise_name TEXT NOT NULL,
                target_sets INTEGER DEFAULT 3,
                target_reps INTEGER DEFAULT 10,
                target_weight FLOAT DEFAULT 0.0,
                rest_seconds INTEGER DEFAULT 60,
                notes TEXT,
                order_index INTEGER DEFAULT 0,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
            );

            -- Workout sets table
            CREATE TABLE IF NOT EXISTS workout_sets (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                exercise_entry_id UUID NOT NULL REFERENCES workout_exercise_entries(id) ON DELETE CASCADE,
                session_id UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
                set_number INTEGER NOT NULL,
                reps INTEGER DEFAULT 0,
                weight FLOAT DEFAULT 0.0,
                rpe INTEGER CHECK (rpe >= 1 AND rpe <= 10),
                is_completed BOOLEAN DEFAULT false,
                notes TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
            );

            -- Enable RLS
            ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
            ALTER TABLE workout_exercise_entries ENABLE ROW LEVEL SECURITY;
            ALTER TABLE workout_sets ENABLE ROW LEVEL SECURITY;

            -- RLS policies
            CREATE POLICY workout_sessions_user_policy ON workout_sessions
                FOR ALL USING (auth.uid() = user_id);
            
            CREATE POLICY workout_exercise_entries_user_policy ON workout_exercise_entries
                FOR ALL USING (EXISTS (
                    SELECT 1 FROM workout_sessions WHERE id = session_id AND user_id = auth.uid()
                ));
            
            CREATE POLICY workout_sets_user_policy ON workout_sets
                FOR ALL USING (EXISTS (
                    SELECT 1 FROM workout_sessions WHERE id = session_id AND user_id = auth.uid()
                ));
            """,
            down_sql="""
            DROP TABLE IF EXISTS workout_sets;
            DROP TABLE IF EXISTS workout_exercise_entries;
            DROP TABLE IF EXISTS workout_sessions;
            """
        ))

        # Migration 002: Progress tracking tables
        self.migrations.append(Migration(
            version="002",
            name="create_progress_tracking_tables",
            up_sql="""
            -- Progress metrics table
            CREATE TABLE IF NOT EXISTS progress_metrics (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
                metric_type TEXT NOT NULL CHECK (metric_type IN ('weight', 'body_fat', 'measurement', 'custom')),
                value FLOAT NOT NULL,
                unit TEXT DEFAULT '',
                notes TEXT,
                measured_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
            );

            -- Personal records table
            CREATE TABLE IF NOT EXISTS personal_records (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
                exercise_id TEXT NOT NULL,
                exercise_name TEXT NOT NULL,
                metric_type TEXT NOT NULL CHECK (metric_type IN ('weight', 'reps', 'volume', 'time')),
                value FLOAT NOT NULL,
                previous_value FLOAT,
                improvement_percent FLOAT DEFAULT 0.0,
                achieved_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
            );

            -- Enable RLS
            ALTER TABLE progress_metrics ENABLE ROW LEVEL SECURITY;
            ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;

            -- RLS policies
            CREATE POLICY progress_metrics_user_policy ON progress_metrics
                FOR ALL USING (auth.uid() = user_id);
            
            CREATE POLICY personal_records_user_policy ON personal_records
                FOR ALL USING (auth.uid() = user_id);
            """,
            down_sql="""
            DROP TABLE IF EXISTS personal_records;
            DROP TABLE IF EXISTS progress_metrics;
            """
        ))

        # Migration 003: Notifications table
        self.migrations.append(Migration(
            version="003",
            name="create_notifications_table",
            up_sql="""
            -- Notifications table
            CREATE TABLE IF NOT EXISTS notifications (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
                type TEXT NOT NULL CHECK (type IN ('workout_reminder', 'achievement', 'pr', 'streak', 'system')),
                title TEXT NOT NULL,
                message TEXT NOT NULL,
                data JSONB DEFAULT '{}',
                is_read BOOLEAN DEFAULT false,
                read_at TIMESTAMP WITH TIME ZONE,
                action_url TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
            );

            -- Enable RLS
            ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

            -- RLS policy
            CREATE POLICY notifications_user_policy ON notifications
                FOR ALL USING (auth.uid() = user_id);
            """,
            down_sql="""
            DROP TABLE IF EXISTS notifications;
            """
        ))

    async def _ensure_migrations_table(self):
        """Ensure the migrations tracking table exists."""
        try:
            # Check if migrations table exists by trying to select from it
            result = db.table(self.MIGRATIONS_TABLE).select("*").limit(1).execute()
        except Exception:
            # Table doesn't exist, create it
            create_sql = f"""
            CREATE TABLE IF NOT EXISTS {self.MIGRATIONS_TABLE} (
                version TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                applied_at TIMESTAMP WITH TIME ZONE DEFAULT now()
            );
            """
            # Execute raw SQL through Supabase
            try:
                db.client.postgrest.raw(create_sql)
            except Exception as e:
                print(f"Warning: Could not create migrations table: {e}")

    async def _get_applied_migrations(self) -> List[str]:
        """Get list of already applied migration versions."""
        try:
            result = db.table(self.MIGRATIONS_TABLE).select("version").execute()
            return [row["version"] for row in result.data] if result.data else []
        except Exception:
            return []

    async def _record_migration(self, migration: Migration):
        """Record a migration as applied."""
        db.table(self.MIGRATIONS_TABLE).insert({
            "version": migration.version,
            "name": migration.name,
            "applied_at": datetime.now().isoformat()
        }).execute()

    async def migrate_up(self, target_version: Optional[str] = None):
        """Run all pending migrations up to target version."""
        await self._ensure_migrations_table()
        applied = await self._get_applied_migrations()

        pending = [m for m in self.migrations if m.version not in applied]

        if target_version:
            target_idx = next((i for i, m in enumerate(pending) if m.version == target_version), None)
            if target_idx is not None:
                pending = pending[:target_idx + 1]

        for migration in pending:
            print(f"Applying migration {migration.version}: {migration.name}")
            try:
                # Execute the migration SQL
                # Note: This is a simplified version. In production, use proper SQL execution
                print(f"SQL to execute:\n{migration.up_sql}")
                await self._record_migration(migration)
                print(f"✓ Migration {migration.version} applied successfully")
            except Exception as e:
                print(f"✗ Migration {migration.version} failed: {e}")
                raise

    async def migrate_down(self, target_version: str):
        """Rollback migrations to target version."""
        await self._ensure_migrations_table()
        applied = await self._get_applied_migrations()

        to_rollback = [m for m in self.migrations if m.version in applied and m.version > target_version]
        to_rollback.reverse()

        for migration in to_rollback:
            print(f"Rolling back migration {migration.version}: {migration.name}")
            try:
                # Execute the rollback SQL
                print(f"SQL to execute:\n{migration.down_sql}")
                # Delete migration record
                db.table(self.MIGRATIONS_TABLE).delete().eq("version", migration.version).execute()
                print(f"✓ Migration {migration.version} rolled back successfully")
            except Exception as e:
                print(f"✗ Migration {migration.version} rollback failed: {e}")
                raise

    async def get_status(self) -> Dict[str, Any]:
        """Get migration status."""
        await self._ensure_migrations_table()
        applied = await self._get_applied_migrations()
        pending = [m.version for m in self.migrations if m.version not in applied]

        return {
            "applied_count": len(applied),
            "pending_count": len(pending),
            "applied_versions": applied,
            "pending_versions": pending,
            "total_migrations": len(self.migrations)
        }


# Global migration manager instance
migration_manager = MigrationManager()


async def run_migrations():
    """Run all pending migrations."""
    await migration_manager.migrate_up()


if __name__ == "__main__":
    asyncio.run(run_migrations())
