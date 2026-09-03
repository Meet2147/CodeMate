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
            companies: [.google, .amazon, .microsoft],
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
            companies: [.amazon, .google, .microsoft],
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
            companies: [.google, .amazon, .microsoft, .apple],
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
            companies: [.google, .microsoft, .amazon],
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
            companies: [.google, .amazon],
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
        )
    ]

    static func question(id: String) -> SystemDesignQuestion? {
        all.first { $0.id == id }
    }
}
