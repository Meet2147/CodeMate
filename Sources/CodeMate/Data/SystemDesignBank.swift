import Foundation

/// Curated, original-phrasing LLD/HLD prep content. These are structured as
/// study scaffolds (requirements -> entities/APIs -> data model -> scaling)
/// rather than full model answers, so the assistant can coach the student
/// through filling each section in rather than handing over a finished design.
enum SystemDesignBank {
    static let all: [SystemDesignQuestion] = [

        SystemDesignQuestion(
            id: "lld-parking-lot",
            title: "Design a Parking Lot",
            scope: .lld,
            companies: [.amazon, .microsoft],
            difficulty: .medium,
            prompt: "Design the classes for a multi-level parking lot that supports multiple vehicle sizes, ticketing, and payment.",
            clarifyingQuestions: [
                "How many levels and spots, and are spot sizes uniform (motorcycle/car/bus)?",
                "Is pricing flat, per-hour, or tiered by vehicle type?",
                "Do we need to support reservations, or only walk-in/park-on-arrival?"
            ],
            sections: [
                DesignSection(heading: "Core entities", bullets: [
                    "ParkingLot (has many Levels)", "Level (has many Spots)", "Spot (size, isOccupied)",
                    "Vehicle (size, licensePlate) with subtypes Motorcycle/Car/Bus",
                    "Ticket (entryTime, spot, vehicle)", "Payment (amount, method, ticket)"
                ]),
                DesignSection(heading: "Key operations / interfaces", bullets: [
                    "ParkingLot.parkVehicle(vehicle) -> Ticket — finds a free, size-appropriate spot",
                    "ParkingLot.unparkVehicle(ticket) -> Payment — frees the spot, computes fee",
                    "SpotAssignmentStrategy — pluggable (nearest-first, level-balancing) so allocation logic isn't hardcoded"
                ]),
                DesignSection(heading: "Design principles to call out", bullets: [
                    "Strategy pattern for spot assignment and for pricing (flat vs hourly vs tiered)",
                    "Single Responsibility: Ticket doesn't compute price, a PricingPolicy does",
                    "Concurrency: two cars racing for the same spot — needs spot-level locking or atomic reservation"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How do you support electric vehicle charging spots?",
                    "How would you extend this to multiple physical parking lots (a chain)?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "lld-elevator-system",
            title: "Design an Elevator System",
            scope: .lld,
            companies: [.amazon, .microsoft, .google],
            difficulty: .medium,
            prompt: "Design the classes and scheduling logic for a bank of elevators in a building.",
            clarifyingQuestions: [
                "How many elevators and floors?",
                "Do we optimize for average wait time, or worst-case starvation?",
                "Any special floors (e.g. requiring a keycard) or freight elevators?"
            ],
            sections: [
                DesignSection(heading: "Core entities", bullets: [
                    "Elevator (currentFloor, direction, state, requestQueue)",
                    "ElevatorController / Dispatcher (assigns hall calls to elevators)",
                    "Request (floor, direction) for hall calls; (floor) for cabin calls"
                ]),
                DesignSection(heading: "Key operations / interfaces", bullets: [
                    "Dispatcher.requestElevator(floor, direction) -> assigns best elevator",
                    "Elevator.step() -> advances one tick: move, open/close doors, service requests",
                    "SchedulingStrategy — pluggable (nearest-elevator, SCAN/look algorithm, zone-based)"
                ]),
                DesignSection(heading: "Design principles to call out", bullets: [
                    "State pattern for elevator state (Idle/MovingUp/MovingDown/DoorsOpen)",
                    "SCAN (elevator) algorithm to avoid starving requests at the ends of the queue",
                    "Observer pattern: floor displays subscribe to elevator position updates"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How would you prioritize during a fire alarm (all elevators go to ground)?",
                    "How do you avoid one elevator hogging all requests while others sit idle?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "lld-rate-limiter",
            title: "Design a Rate Limiter",
            scope: .lld,
            companies: [.google, .amazon, .microsoft, .openai, .twitter],
            difficulty: .medium,
            prompt: "Design a rate limiter that can be dropped into an API gateway to cap requests per client per time window.",
            clarifyingQuestions: [
                "Per-user, per-IP, or per-API-key limiting?",
                "Hard cutoff, or should it support bursts (some elasticity)?",
                "Single server or does this need to work across a distributed fleet?"
            ],
            sections: [
                DesignSection(heading: "Algorithm choices", bullets: [
                    "Fixed window counter — simple, but allows 2x burst at window boundaries",
                    "Sliding window log — accurate, but O(requests) memory per client",
                    "Sliding window counter — good approximation, O(1) memory",
                    "Token bucket — naturally supports bursts up to bucket size, smooth refill",
                    "Leaky bucket — smooths bursts into a constant output rate"
                ]),
                DesignSection(heading: "Core entities", bullets: [
                    "RateLimiter (protocol): allowRequest(clientId) -> Bool",
                    "TokenBucket (capacity, refillRate, tokensAvailable, lastRefillTime)",
                    "RateLimiterStore — where per-client state lives (in-memory map, or Redis for distributed)"
                ]),
                DesignSection(heading: "Design principles to call out", bullets: [
                    "Strategy pattern to swap algorithms without touching the gateway code",
                    "For a distributed system: centralize state in Redis with atomic INCR/EXPIRE, or use a token-bucket Lua script for atomicity",
                    "Fail-open vs fail-closed if the rate-limiter store itself is unreachable"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How do you rate-limit fairly across multiple gateway nodes without a shared store?",
                    "How would you give some clients higher limits (tiered plans)?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-url-shortener",
            title: "Design a URL Shortener",
            scope: .hld,
            companies: [.amazon, .google, .microsoft, .twitter, .linkedin],
            difficulty: .medium,
            prompt: "Design a service like bit.ly: given a long URL, return a short one that redirects to it, at scale.",
            clarifyingQuestions: [
                "Expected scale — reads vs writes per second? (Typically read-heavy, ~100:1)",
                "Do short codes need to be unguessable, or is sequential/short fine?",
                "Do links expire, and do we need click analytics?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: shorten(url) -> code; redirect(code) -> 301/302 to original url",
                    "Non-functional: low-latency redirect (read path is critical), high availability, codes must be unique"
                ]),
                DesignSection(heading: "API design", bullets: [
                    "POST /shorten { longUrl } -> { shortUrl }",
                    "GET /{code} -> 302 redirect to longUrl",
                    "GET /{code}/stats -> click analytics (optional)"
                ]),
                DesignSection(heading: "Data model", bullets: [
                    "urls table: code (PK), longUrl, createdAt, expiresAt, ownerId",
                    "Short code generation: base62-encode an auto-incrementing ID, OR hash+truncate longUrl with collision retry",
                    "Read-heavy — a cache (e.g. Redis) in front of the DB for hot codes is essential"
                ]),
                DesignSection(heading: "Scaling & trade-offs", bullets: [
                    "Horizontally scale stateless redirect servers behind a load balancer",
                    "ID generation at scale: a dedicated ID-generation service (like Snowflake) avoids a single auto-increment bottleneck",
                    "CDN/edge caching for redirects since the mapping rarely changes after creation",
                    "Analytics writes should be async (a queue) so they never slow down the redirect path"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How do you prevent malicious/abusive URLs from being shortened?",
                    "How would you support custom aliases without colliding with generated codes?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-news-feed",
            title: "Design a News Feed (Social Timeline)",
            scope: .hld,
            companies: [.google, .amazon, .microsoft, .apple, .twitter, .meta, .linkedin],
            difficulty: .hard,
            prompt: "Design a system that generates a personalized, roughly-chronological feed of posts from people a user follows, at large scale.",
            clarifyingQuestions: [
                "Rough scale — how many users, how many follow how many others (celebrity/fan-out problem)?",
                "Does the feed need to be strictly real-time, or is a few seconds of staleness fine?",
                "Ranking: pure recency, or an engagement-based ranking model?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: publish(post); getFeed(userId) -> ranked list of recent posts from followees",
                    "Non-functional: feed reads must be fast (<200ms), writes (posting) can tolerate slightly more latency"
                ]),
                DesignSection(heading: "Core approaches", bullets: [
                    "Fan-out on write (push): when a user posts, push the post into every follower's precomputed feed — fast reads, expensive for celebrities with millions of followers",
                    "Fan-out on read (pull): compute the feed at request time by merging followees' recent posts — cheap writes, slower/more expensive reads",
                    "Hybrid: push for normal users, pull-and-merge for celebrity accounts (avoids the 'fan-out explosion')"
                ]),
                DesignSection(heading: "Data model / storage", bullets: [
                    "posts table/store: postId, authorId, content, createdAt (often a wide-column or document store for scale)",
                    "follow graph: followerId -> followeeId edges (graph or adjacency-list store)",
                    "per-user feed cache: a bounded, precomputed list of recent post IDs (Redis sorted set, sorted by timestamp)"
                ]),
                DesignSection(heading: "Scaling & trade-offs", bullets: [
                    "Shard the feed cache and post store by userId/postId to spread load",
                    "Async message queue between 'post created' and 'fan-out worker' decouples write latency from fan-out cost",
                    "CDN/edge caching for media attached to posts",
                    "Ranking model (if not pure chronological) usually runs as a separate re-ranking service on top of the candidate set"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How do you handle a celebrity with 50M followers posting (the fan-out explosion)?",
                    "How would you support real-time updates (new post appears without a refresh)?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-chat-system",
            title: "Design a Real-Time Chat System",
            scope: .hld,
            companies: [.google, .microsoft, .amazon, .meta, .linkedin],
            difficulty: .hard,
            prompt: "Design a system like WhatsApp/iMessage: 1:1 and group messaging, delivery/read receipts, online presence.",
            clarifyingQuestions: [
                "1:1 only, or also group chats? Any group-size limit?",
                "Do we need end-to-end encryption?",
                "Offline delivery — do messages need to be stored and delivered when a user reconnects?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: send/receive messages, delivery + read receipts, presence (online/offline/typing)",
                    "Non-functional: low latency delivery, messages not lost even if recipient is offline, ordering per-conversation"
                ]),
                DesignSection(heading: "Core architecture", bullets: [
                    "Persistent connections (WebSocket) between clients and a fleet of chat/gateway servers",
                    "A connection-routing layer (e.g. a presence/session service) tracks which gateway server each user is connected to",
                    "Sending a message: client -> sender's gateway -> lookup recipient's gateway (or queue if offline) -> deliver -> ack back through the chain"
                ]),
                DesignSection(heading: "Data model", bullets: [
                    "messages table: messageId, conversationId, senderId, content, timestamp, status (sent/delivered/read)",
                    "conversations table: conversationId, participantIds, lastMessageAt",
                    "offline message queue per user, drained on reconnect"
                ]),
                DesignSection(heading: "Scaling & trade-offs", bullets: [
                    "Shard conversations across message-store nodes by conversationId for write scaling",
                    "Use a pub/sub layer (or a message queue) between gateway servers so a message can reach a recipient connected to a *different* server",
                    "Group chats fan out to N participants — similar trade-offs to the news-feed fan-out problem at large group sizes",
                    "Read receipts are high-write, low-criticality — good candidate for async/batched updates instead of blocking the send path"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How do you guarantee message ordering within a conversation across servers?",
                    "How would you add end-to-end encryption without breaking search/backup features?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-web-crawler",
            title: "Design a Web Crawler",
            scope: .hld,
            companies: [.google, .amazon, .openai],
            difficulty: .hard,
            prompt: "Design a scalable web crawler that discovers and downloads pages across the web, respecting robots.txt and avoiding duplicate/infinite crawls.",
            clarifyingQuestions: [
                "Goal: search indexing, broad archival, or a focused crawl on a topic/domain set?",
                "Politeness constraints — how do we avoid hammering a single host?",
                "Freshness — do we need to re-crawl pages periodically?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: given seed URLs, discover linked pages and store their content; avoid re-crawling duplicates",
                    "Non-functional: scalable to billions of pages, polite (rate-limited per host), resilient to crawler traps (infinite link loops)"
                ]),
                DesignSection(heading: "Core architecture", bullets: [
                    "URL frontier (a prioritized, politeness-aware queue) feeding a fleet of fetcher workers",
                    "Fetcher -> parser (extract links + content) -> dedup filter -> back into the frontier / into storage",
                    "DNS resolution and robots.txt caching layers to avoid redundant lookups"
                ]),
                DesignSection(heading: "Data model / storage", bullets: [
                    "URL frontier: per-host queues + a scheduler that round-robins hosts to enforce politeness delay",
                    "Seen-URL set: a Bloom filter (or distributed key-value store) to cheaply check 'have we crawled this?' at huge scale",
                    "Content store: blob storage keyed by URL/content-hash, deduplicated by content hash (mirrors/duplicates)"
                ]),
                DesignSection(heading: "Scaling & trade-offs", bullets: [
                    "Partition the frontier by host so one crawler node handles all requests to a given host (natural politeness enforcement)",
                    "Bloom filter trades a small false-positive rate for massive memory savings on the seen-URL set",
                    "Crawler traps (e.g. calendar pages generating infinite URLs) need heuristics: max depth, max URLs per host, URL pattern detection"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How do you prioritize re-crawling frequently-changing pages (like news) over static ones?",
                    "How would you detect and skip near-duplicate content across different URLs?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "lld-tic-tac-toe",
            title: "Design a Multiplayer Tic-Tac-Toe Engine",
            scope: .lld,
            companies: [.apple, .microsoft],
            difficulty: .easy,
            prompt: "Design the classes for a tic-tac-toe game engine that could back a multiplayer game (turn validation, win detection, replay).",
            clarifyingQuestions: [
                "Fixed 3x3, or should the board size be configurable (NxN, win = N in a row)?",
                "Do we need move history / replay, or just current state?",
                "Local two-player, or networked (does the engine need to be authoritative against cheating)?"
            ],
            sections: [
                DesignSection(heading: "Core entities", bullets: [
                    "Board (grid, size)", "Player (id, symbol)", "Move (player, row, col, timestamp)",
                    "GameEngine (board, players, currentTurn, moveHistory, state)"
                ]),
                DesignSection(heading: "Key operations / interfaces", bullets: [
                    "GameEngine.makeMove(player, row, col) -> validates turn + cell empty, applies move, checks win/draw",
                    "WinChecker — pluggable strategy so board size / win-length can change without touching the engine",
                    "GameEngine.state -> InProgress / Won(player) / Draw"
                ]),
                DesignSection(heading: "Design principles to call out", bullets: [
                    "Keep the engine authoritative and pure (no I/O) so it's independently testable and reusable server-side",
                    "Command pattern for moves enables replay and undo for free",
                    "Validate strictly server-side if networked — never trust the client's claimed win state"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How would you extend this engine to Connect Four with minimal changes?",
                    "How would you add an AI opponent (minimax) behind the same interface?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-llm-inference-queue",
            title: "Design an LLM Inference Serving Queue",
            scope: .hld,
            companies: [.openai, .google, .microsoft],
            difficulty: .hard,
            prompt: "Design the request-serving layer that sits in front of a large language model: it accepts generation requests, queues and batches them onto a fleet of GPU workers, and streams tokens back to callers.",
            clarifyingQuestions: [
                "Is output streamed token-by-token, or returned only once generation finishes?",
                "Do requests vary a lot in expected output length, and does that matter for scheduling?",
                "Are there different priority tiers (e.g. paying API customers vs. best-effort batch jobs)?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: accept a prompt, return generated tokens (streamed); support cancellation mid-generation",
                    "Non-functional: high GPU utilization (GPUs are the scarce, expensive resource), low time-to-first-token, fairness across tenants"
                ]),
                DesignSection(heading: "Core architecture", bullets: [
                    "API gateway accepts requests, assigns a request ID, pushes onto a priority queue",
                    "A scheduler dynamically batches multiple requests together onto a single GPU worker's forward pass ('continuous batching') to keep GPUs busy",
                    "Each GPU worker streams generated tokens back through the gateway to the originating client connection as they're produced"
                ]),
                DesignSection(heading: "Key trade-offs", bullets: [
                    "Larger batches -> better GPU throughput, but can increase time-to-first-token for requests batched in later",
                    "Static batching (wait for a full batch) is simple but wastes GPU time; continuous/dynamic batching (admit new requests into an in-flight batch) is far more GPU-efficient but more complex to implement",
                    "KV-cache memory per in-flight request limits how many requests a GPU can serve concurrently -- this, not raw compute, is often the real bottleneck",
                    "Request queueing needs a fairness policy (e.g. weighted fair queueing across API keys) so one heavy tenant can't starve others"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How would you handle a GPU worker crashing mid-batch, without losing every request in that batch?",
                    "How would you route requests across multiple model versions or model sizes based on request complexity?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-trending-topics",
            title: "Design a Trending Topics System",
            scope: .hld,
            companies: [.twitter, .meta],
            difficulty: .medium,
            prompt: "Design a system that surfaces currently-trending hashtags/topics from a huge, continuous stream of posts, updated in near real time.",
            clarifyingQuestions: [
                "How 'real time' does trending need to be -- seconds, or is a minute of staleness fine?",
                "Trending globally, or personalized/localized per region or per user's network?",
                "Do we need to defend against coordinated spam artificially inflating a topic's count?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: ingest a high-volume post stream, extract topics/hashtags, surface the top-N trending right now",
                    "Non-functional: near-real-time updates, must handle massive write throughput without an exact-count database write per post"
                ]),
                DesignSection(heading: "Core architecture", bullets: [
                    "Stream processing layer (e.g. a windowed stream processor) consumes the post firehose and extracts/counts topics over sliding time windows",
                    "Approximate counting structures (e.g. Count-Min Sketch) avoid needing exact per-topic counters at massive scale, trading small, bounded error for huge memory/throughput savings",
                    "A top-K structure (e.g. a bounded heap per time window) tracks the current leaderboard without sorting the entire topic space"
                ]),
                DesignSection(heading: "Key trade-offs", bullets: [
                    "'Trending' usually means a topic's rate of increase, not just raw volume -- compare recent-window counts to a longer baseline to detect spikes, not just popularity",
                    "Approximate counting sacrifices exactness for the throughput needed at this scale -- worth calling out explicitly as a deliberate trade-off",
                    "Spam/bot detection (e.g. rate-limiting how much a single account can contribute to a topic's count) is essential or the leaderboard is trivially gameable"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How would you personalize trends per region without running the whole pipeline once per region?",
                    "How would you detect and suppress an artificially-boosted (spam/bot) topic?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-streaming-recommendations",
            title: "Design a Video Streaming & Recommendation Service",
            scope: .hld,
            companies: [.netflix, .amazon, .google],
            difficulty: .hard,
            prompt: "Design the core of a video streaming service: efficient global video delivery, plus a personalized 'what to watch next' recommendation feed on the home screen.",
            clarifyingQuestions: [
                "Are we designing delivery (CDN/encoding), recommendations, or both end to end?",
                "Personalized recommendations, or also 'trending now' / editorially curated rows?",
                "What's the acceptable staleness for recommendations -- do they need to react to what a user just watched minutes ago?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: stream video with adaptive quality; serve a personalized, ranked list of recommended titles",
                    "Non-functional: low startup/buffering latency globally, recommendations must scale to a huge catalog and user base"
                ]),
                DesignSection(heading: "Delivery architecture", bullets: [
                    "Videos are pre-encoded at multiple bitrates/resolutions; a CDN caches and serves segments close to the viewer (adaptive bitrate streaming, e.g. HLS/DASH)",
                    "Origin storage holds the master encodes; CDN edge nodes are populated lazily or pre-warmed for anticipated-popular titles"
                ]),
                DesignSection(heading: "Recommendation architecture", bullets: [
                    "Offline/batch layer: periodically trains a recommendation model on historical watch/rating data (collaborative filtering, embeddings, etc.)",
                    "Online/serving layer: given a user, fetches a candidate set (from the offline model output, cached), then re-ranks using recent signals (what they just watched, time of day)",
                    "A candidate-generation + re-ranking split keeps the expensive model work offline while the online path stays fast"
                ]),
                DesignSection(heading: "Key trade-offs", bullets: [
                    "Pre-computing recommendations per user (push) is fast to serve but goes stale between batch runs; computing on-demand (pull) is fresher but more expensive per request -- most real systems hybridize, similar to the news-feed fan-out trade-off",
                    "CDN cache-hit rate dominates delivery cost and latency -- predicting which titles need pre-warming where is its own sub-problem",
                    "Cold-start (new user or new title with no watch history) needs a fallback strategy (popularity-based or content-based, not pure collaborative filtering)"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How would you A/B test a new recommendation model safely against the current one?",
                    "How would you handle a sudden regional spike in demand for one newly-released title?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-ride-hailing-dispatch",
            title: "Design a Ride-Hailing Dispatch System",
            scope: .hld,
            companies: [.uber, .google, .amazon],
            difficulty: .hard,
            prompt: "Design the core matching system for a ride-hailing app: continuously track nearby available drivers and match them to incoming ride requests in real time.",
            clarifyingQuestions: [
                "What's an acceptable match latency -- sub-second, or a few seconds is fine?",
                "Do we optimize purely for nearest driver, or also for fairness/earnings balance across drivers?",
                "How often do driver locations update, and how many concurrent drivers/riders are we targeting in one city?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: drivers continuously report location; riders request a ride; the system matches a rider to a nearby available driver",
                    "Non-functional: low-latency matching, must scale to a dense city with many thousands of concurrent drivers reporting location every few seconds"
                ]),
                DesignSection(heading: "Core architecture", bullets: [
                    "Drivers stream location updates over a persistent connection to a location service, which indexes them geospatially",
                    "A geospatial index (e.g. a grid/geohash or quadtree over the city) lets the matcher query 'available drivers near this rider' in roughly constant time instead of scanning all drivers",
                    "A matching service takes a ride request, queries nearby available drivers from the index, ranks candidates (distance, ETA, driver rating), and dispatches a request to the chosen driver"
                ]),
                DesignSection(heading: "Key trade-offs", bullets: [
                    "Geohash/grid-cell indexing is simple and fast but has edge effects near cell boundaries (nearest driver might be in an adjacent cell) -- typically mitigated by also checking neighboring cells",
                    "Driver location data is high-write, low-durability-requirement (a stale-by-a-few-seconds location is fine) -- a good candidate for in-memory storage rather than a durable database on the hot path",
                    "Matching is inherently a trade-off between 'nearest driver' (best for this rider) and city-wide efficiency (best overall) -- pure greedy nearest-match can leave the system globally worse off during high demand"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How would you handle surge pricing/demand spikes overwhelming available driver supply in one area?",
                    "How would you make matching resilient to a driver going offline right after being matched?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-distributed-job-scheduler",
            title: "Design a Distributed Job Scheduler",
            scope: .hld,
            companies: [.google, .amazon, .uber],
            difficulty: .hard,
            prompt: "Design a system that lets services schedule jobs to run at a specific time or on a recurring cron-like schedule, reliably executing them exactly once even as workers come and go.",
            clarifyingQuestions: [
                "Do jobs need exactly-once execution, or is at-least-once (with idempotent jobs) acceptable?",
                "What's the expected job volume and how far in advance are jobs typically scheduled?",
                "Do jobs need to run on specific worker types (e.g. GPU jobs vs. CPU jobs)?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: schedule a one-off or recurring job; execute it at the right time; retry on failure; support cancellation",
                    "Non-functional: durable (a scheduled job survives a crash), scales to a high volume of jobs, low scheduling-to-execution latency"
                ]),
                DesignSection(heading: "Core architecture", bullets: [
                    "A durable job store (database) holds job definitions plus their next-run time",
                    "A scheduler/dispatcher polls (or is notified of) jobs whose next-run time has arrived and pushes them onto a work queue",
                    "A pool of workers pulls from the queue, executes the job, and reports success/failure back to the job store",
                    "On failure, the dispatcher re-enqueues with backoff, up to a retry limit"
                ]),
                DesignSection(heading: "Key trade-offs", bullets: [
                    "Exactly-once execution is genuinely hard in a distributed system -- most real schedulers aim for at-least-once delivery and require jobs to be idempotent, using a dedup key to detect an accidental re-run",
                    "A single dispatcher polling the job store doesn't scale -- typically sharded by time bucket or job-id hash so multiple dispatcher instances can work in parallel without double-claiming",
                    "A worker crashing mid-job needs a visibility timeout / lease mechanism (like SQS) so its job gets reclaimed by another worker instead of silently vanishing"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How would you handle a job that consistently fails (a 'poison' job) without it clogging retries forever?",
                    "How would you support job priorities so urgent jobs don't wait behind a backlog of low-priority ones?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-collaborative-whiteboard",
            title: "Design a Collaborative Whiteboard",
            scope: .hld,
            companies: [.meta, .google, .microsoft],
            difficulty: .hard,
            prompt: "Design a real-time collaborative whiteboard (like the one in this app!) where multiple people can draw shapes, text, and freehand strokes on the same canvas at once and see each other's changes live.",
            clarifyingQuestions: [
                "How many concurrent editors on one board -- a handful (pair design session) or hundreds?",
                "Do we need offline support (someone edits while disconnected, then reconnects)?",
                "Does history/undo need to be per-user or global across the whole board?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: multiple users draw on a shared canvas; changes propagate to everyone in near-real-time; persist the board so it can be reopened later",
                    "Non-functional: low-latency propagation (feels 'live'), consistent final state even when two people edit concurrently"
                ]),
                DesignSection(heading: "Core architecture", bullets: [
                    "Each client maintains a local copy of the board's elements (strokes/shapes) and renders optimistically as the user draws",
                    "A WebSocket connection to a real-time server broadcasts each new/changed element to every other connected client on that board",
                    "The server persists elements to a database (or an append-only log of operations) so the board survives disconnects and can be reloaded"
                ]),
                DesignSection(heading: "Key trade-offs", bullets: [
                    "Naive 'last write wins' on conflicting edits can silently lose someone's work -- CRDTs (conflict-free replicated data types) or operational transforms let concurrent edits merge deterministically without a central lock, at the cost of real implementation complexity",
                    "For a whiteboard specifically, most elements (individual strokes/shapes) are independently addressable and rarely edited by two people at the exact same instant -- so many real products get away with simple last-write-wins per element instead of full OT/CRDT, trading rare edge-case data loss for much simpler engineering",
                    "Broadcasting via a central server is simple but adds a hop of latency; peer-to-peer (WebRTC data channels) cuts latency further but complicates the 'who has the source of truth' story"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How would you implement undo/redo when other people might have drawn on top of the element you're undoing?",
                    "How would you scale one hugely popular board past what a single server's WebSocket connections can hold?"
                ])
            ]
        ),

        SystemDesignQuestion(
            id: "hld-payments-checkout",
            title: "Design a Payments / Checkout System",
            scope: .hld,
            companies: [.amazon, .uber],
            difficulty: .hard,
            prompt: "Design the checkout system for an e-commerce or ride-hailing platform: charge a customer's payment method reliably, exactly once, even if network calls fail partway through.",
            clarifyingQuestions: [
                "Are we integrating with an external payment processor (Stripe-like), or building payment processing itself?",
                "Do we need to support partial refunds and disputes/chargebacks?",
                "What's the acceptable latency for a checkout to complete?"
            ],
            sections: [
                DesignSection(heading: "Requirements", bullets: [
                    "Functional: charge a payment method for an order; handle success/failure/timeout from the processor; support refunds",
                    "Non-functional: a charge must never happen twice for one order, and money must never simply vanish (no charge lost due to a crash mid-request)"
                ]),
                DesignSection(heading: "Core architecture", bullets: [
                    "An order is created in a 'pending payment' state before any charge attempt",
                    "The payment service calls an external processor with a unique idempotency key tied to the order, so a retried request after a timeout doesn't double-charge",
                    "A webhook (or polling) from the processor confirms the final outcome, transitioning the order to paid/failed -- the system doesn't trust only the synchronous response, since that call itself can fail after the charge actually succeeded"
                ]),
                DesignSection(heading: "Key trade-offs", bullets: [
                    "The hardest part isn't charging a card -- it's handling the 'we don't know if it worked' case when a network call to the processor times out. Idempotency keys plus reconciling against the processor's own webhook/record of truth is how real systems solve this, rather than assuming a timeout means failure",
                    "Synchronous, in-request charging is simple but ties your checkout's latency and reliability to the payment processor's; an async pattern (mark pending, confirm via webhook, notify the user) is more resilient but means checkout isn't instantly 'done' from the user's point of view",
                    "Idempotency keys need to be stored durably (not just in memory) so a retry after a full service restart still recognizes 'this exact charge was already attempted'"
                ]),
                DesignSection(heading: "Good follow-ups to rehearse", bullets: [
                    "How would you reconcile your internal order records against the payment processor's records if they ever drift out of sync?",
                    "How would you handle a refund for an order that's already been fulfilled/shipped?"
                ])
            ]
        )

    ]

    static func question(id: String) -> SystemDesignQuestion? {
        all.first { $0.id == id }
    }
}
