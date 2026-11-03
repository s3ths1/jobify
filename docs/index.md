# Jobify

**Jobify** is an asynchronous job scheduling framework for Python with event-driven timers, typed APIs, and production-focused execution controls.

<div class="grid cards" markdown>

- :material-timer-outline:{ .lg .middle } **Event-driven Precision**

    ***

    No polling loops. Jobs are triggered via low-level `asyncio` timers.

    [:octicons-arrow-right-24: Why Jobify](#why-jobify){ data-preview }

- :material-calendar-clock:{ .lg .middle } **Flexible Scheduling**

    ***

    Run now, after delay, at timestamp, or via cron (including seconds).

    [:octicons-arrow-right-24: Open Scheduling](schedule.md){ data-preview }

- :material-database-lock:{ .lg .middle } **Built-in Persistence**

    ***

    SQLite storage keeps scheduled jobs across restarts.

    [:octicons-arrow-right-24: Open Storage](app_settings.md#storage){ data-preview }

- :material-sort-variant-lock:{ .lg .middle } **Queue + Backpressure**

    ***

    Control throughput with bounded queues, workers, and priorities.

    [:octicons-arrow-right-24: Open Queue Middleware](advanced_usage/queue.md){ data-preview }

- :material-vector-polyline:{ .lg .middle } **Router-style Organization**

    ***

    Structure tasks with `JobRouter` in a FastAPI-like style.

    [:octicons-arrow-right-24: Open Router](router.md){ data-preview }

- :material-shield-alert-outline:{ .lg .middle } **Failure Handling**

    ***

    Hierarchical exception handlers at global, router, and task levels.

    [:octicons-arrow-right-24: Open Exception Handlers](advanced_usage/exception_handlers.md){ data-preview }

</div>

## Comparison

| Feature name                                                                   |        Jobify        |      Taskiq       | APScheduler (v3) |      Celery       |
| :----------------------------------------------------------------------------- | :------------------: | :---------------: | :--------------: | :---------------: |
| **Event-driven Scheduling**                                                    | ✅ (Low-level timer) | ❌ (Polling/Loop) |  ❌ (Interval)   | ❌ (Polling/Loop) |
| **Async Native (asyncio)**                                                     |          ✅          |        ✅         | ❌ (Sync mostly) |        ❌         |
| [**Context Injection**](context.md){ data-preview }                            |          ✅          |        ✅         |        ❌        |        ❌         |
| [**FastAPI-style Routing**](router.md){ data-preview }                         |          ✅          |        ❌         |        ❌        |        ❌         |
| [**Middleware Support**](app_settings.md#middleware){ data-preview }           |          ✅          |        ✅         | ❌ (Events only) |   ❌ (Signals)    |
| [**Lifespan Support**](app_settings.md#lifespan){ data-preview }               |          ✅          |        ✅         |        ❌        |        ❌         |
| [**Exception Handlers**](advanced_usage/exception_handlers.md){ data-preview } |  ✅ (Hierarchical)   |        ❌         |        ❌        |        ❌         |
| [**Job Cancellation**](job.md#await-jobcancel){ data-preview }                 |          ✅          |        ❌         |        ✅        |        ✅         |
| [**Cron Scheduling**](schedule.md#cron-expressions){ data-preview }            |  ✅ (Seconds level)  |   ✅ (Minutes)    |        ✅        |        ✅         |
| [**Misfire Policy**](schedule.md#the-cron-object){ data-preview }              |          ✅          |        ❌         |        ✅        |        ❌         |
| [**Run Modes (Thread/Process)**](task_settings.md#run_mode){ data-preview }    |          ✅          |        ✅         |        ✅        |        ✅         |
| **Rich Typing Support**                                                        |          ✅          |        ✅         |        ❌        |        ❌         |
| **Zero-config Persistence**                                                    | ✅ (SQLite default)  | ❌ (Needs Broker) |        ✅        | ❌ (Needs Broker) |
| **Broker-backend execution**                                                   |      ❌ (soon)       |        ✅         |        ❌        |        ✅         |

## Why Jobify?

Jobify uses `asyncio.loop.call_at` instead of polling loops.

1. **Efficiency:** No idle CPU usage when nothing is scheduled.
2. **Precision:** Sub-millisecond timing without polling jitter.
3. **Native behavior:** Works with OS event-notification primitives.

!!! note "Precision vs Polling Trade-off"
    Event-driven scheduling is sensitive to significant system clock shifts.
    See [System Time and Scheduling](advanced_usage/system_time.md){ data-preview }.

## Quick Start

### Installation

=== "uv"

    ```bash
    # Standard installation
    uv add jobify

    # With high-performance dependencies (orjson, pydantic)
    uv add "jobify[fast]"
    ```

=== "pip"

    ```bash
    # Standard installation
    pip install jobify

    # With high-performance dependencies (orjson, pydantic)
    pip install "jobify[fast]"
    ```

=== "poetry"

    ```bash
    # Standard installation
    poetry add jobify

    # With high-performance dependencies (orjson, pydantic)
    poetry add jobify -E fast
    ```

### Basic Usage

=== "wait for all jobs"

    ```python linenums="1" hl_lines="31-32"
    import asyncio
    from datetime import datetime, timedelta
    from zoneinfo import ZoneInfo

    from jobify import Jobify, Job

    UTC = ZoneInfo("UTC")
    app = Jobify(tz=UTC)


    @app.task(cron="* * * * * * *")  # every second
    async def my_cron() -> None:
        print("cron tick")


    @app.task
    def my_job(name: str) -> None:
        now = datetime.now(tz=UTC)
        print(f"Hello, {name}! at {now!r}")


    async def main() -> None:
        async with app:
            await my_job.push("Alex")

            run_next_day = datetime.now(tz=UTC) + timedelta(days=1)
            job_at: Job = await my_job.schedule("Connor").at(run_next_day)
            job_delay: Job = await my_job.schedule("Sara").delay(20)
            job_cron: Job = await my_cron.schedule().cron("* * * * *", job_id="dynamic_cron_id")

            # block until every scheduled job is done
            await app.wait_all()


    if __name__ == "__main__":
        asyncio.run(main())
    ```

=== "wait for individual jobs"

    ```python linenums="1" hl_lines="31-33"
    import asyncio
    from datetime import datetime, timedelta
    from zoneinfo import ZoneInfo

    from jobify import Jobify, Job

    UTC = ZoneInfo("UTC")
    app = Jobify(tz=UTC)


    @app.task(cron="* * * * * * *")  # every second
    async def my_cron() -> None:
        print("cron tick")


    @app.task
    def my_job(name: str) -> None:
        now = datetime.now(tz=UTC)
        print(f"Hello, {name}! at {now!r}")


    async def main() -> None:
        async with app:
            await my_job.push("Alex")

            run_next_day = datetime.now(tz=UTC) + timedelta(days=1)
            job_at: Job = await my_job.schedule("Connor").at(run_next_day)
            job_delay: Job = await my_job.schedule("Sara").delay(20)
            job_cron: Job = await my_cron.schedule().cron("* * * * *", job_id="dynamic_cron_id")

            await job_at.wait()
            await job_delay.wait()
            await job_cron.wait()


    if __name__ == "__main__":
        asyncio.run(main())
    ```

### Waiting for jobs

Jobify provides two ways to wait for job execution:

* `#!python await job.wait()` - waits for a specific job to reach a terminal state.
* `#!python await app.wait_all()` - wait until every scheduled job has finished (statuses SUCCESS, FAILED or TIMEOUT). The call returns as soon as the internal jobs registry becomes empty.

This is the simplest way to keep your process alive until the background work is complete, eliminating the need for `#!python while True: sleep()` loops and manual result tracking.
