---
name: sui-move-patterns
description: Sui Move 智能合约开发模式与最佳实践 - 包含常见设计模式、安全注意事项和代码模板
version: 1.0.0
author: DavidRain
license: MIT
metadata:
  hermes:
    tags: [sui, move, smart-contract, blockchain, patterns]
    related_skills: [davidrain]
    category: crafts
---

# Sui Move 开发模式

Sui Move 智能合约开发的最佳实践和常见模式。

---

## 一、何时使用这个 Skill

使用场景：
- ✅ 编写新的 Sui Move 合约
- ✅ 审查 Move 代码
- ✅ 优化 Gas 成本
- ✅ 设计合约架构

---

## 二、核心概念速查

### Object Model

```move
// Sui 的核心：一切皆 Object
struct MyObject has key, store {
    id: UID,
    value: u64,
}
```

| Ability | 含义 | 使用场景 |
|---------|------|----------|
| `key` | 可以作为顶级对象存储 | 所有需要独立存在的对象 |
| `store` | 可以存储在其他对象中 | 需要被包装的对象 |
| `copy` | 可以复制 | 简单值类型 |
| `drop` | 可以丢弃 | 不需要手动销毁的对象 |

### 所有权模型

```move
// 1. 独占所有权 (Owned)
fun create_owned(ctx: &mut TxContext): MyObject {
    MyObject { id: object::new(ctx), value: 100 }
}
// 用户钱包拥有，只有所有者可以操作

// 2. 共享所有权 (Shared)
fun create_shared(obj: MyObject) {
    transfer::share_object(obj);
}
// 任何人都可以访问，需要权限控制

// 3. 不可变对象 (Immutable)
fun freeze_object(obj: MyObject) {
    transfer::freeze_object(obj);
}
// 永久不可变，类似合约常量
```

---

## 三、常见设计模式

### 模式 1: Capability 模式（权限控制）

```move
module my_module::admin {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // 权限凭证 - 只有拥有者可以执行敏感操作
    struct AdminCap has key, store {
        id: UID,
    }

    // 初始化时创建 AdminCap 并发送给部署者
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            AdminCap { id: object::new(ctx) },
            tx_context::sender(ctx)
        );
    }

    // 需要 AdminCap 才能调用的函数
    public entry fun sensitive_operation(
        _: &AdminCap,  // 通过 _ 表示不使用但需要验证存在
        // ... 其他参数
    ) {
        // 敏感操作
    }
}
```

**使用场景**: 管理员功能、权限分层

### 模式 2: Registry 模式（对象注册表）

```move
module my_module::registry {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::vec_set::{Self, VecSet};

    // 共享的注册表对象
    struct Registry has key {
        id: UID,
        items: VecSet<ID>,  // 存储对象 ID
        owner: address,
    }

    // 初始化时创建共享注册表
    fun init(ctx: &mut TxContext) {
        transfer::share_object(Registry {
            id: object::new(ctx),
            items: vec_set::empty(),
            owner: tx_context::sender(ctx),
        });
    }

    // 添加条目（需要权限检查）
    public entry fun register(
        registry: &mut Registry,
        item_id: ID,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == registry.owner, 0);
        vec_set::insert(&mut registry.items, item_id);
    }
}
```

**使用场景**: 任务市场、用户列表、对象索引

### 模式 3: Event 模式（链上日志）

```move
module my_module::events {
    use sui::event;

    // 定义事件结构
    struct TaskCreated has copy, drop {
        task_id: ID,
        creator: address,
        reward: u64,
    }

    struct TaskCompleted has copy, drop {
        task_id: ID,
        executor: address,
    }

    // 触发事件
    public fun emit_task_created(task_id: ID, creator: address, reward: u64) {
        event::emit(TaskCreated { task_id, creator, reward });
    }
}
```

**使用场景**: 前端监听、数据分析、用户通知

### 模式 4: Wrapper 模式（对象包装）

```move
module my_module::wrapper {
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;

    // 包装 SUI 代币和其他数据
    struct Task has key, store {
        id: UID,
        reward: Balance<SUI>,  // 包装代币
        description: String,
        status: u8,  // 0: Open, 1: InProgress, 2: Completed
    }

    // 创建任务时存入奖励
    public entry fun create_task(
        reward: Coin<SUI>,
        description: String,
        ctx: &mut TxContext,
    ) {
        let task = Task {
            id: object::new(ctx),
            reward: coin::into_balance(reward),
            description,
            status: 0,
        };
        transfer::share_object(task);
    }

    // 完成任务时提取奖励
    public entry fun complete_task(
        task: &mut Task,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        assert!(task.status == 1, 0);
        task.status = 2;
        coin::from_balance(balance::withdraw_all(&mut task.reward), ctx)
    }
}
```

**使用场景**: 任务市场、托管合约、NFT 包装

---

## 四、安全最佳实践

### 1. 输入验证

```move
// ✅ 好的做法：验证所有输入
public entry fun deposit(
    amount: u64,
    ctx: &mut TxContext,
) {
    assert!(amount > 0, EInvalidAmount);  // 验证正数
    assert!(amount <= MAX_DEPOSIT, EAmountTooLarge);  // 验证上限
    // ...
}

// ❌ 坏的做法：不验证输入
public entry fun deposit_bad(amount: u64) {
    // 直接接受任何值
}
```

### 2. 权限检查

```move
// ✅ 好的做法：显式权限检查
public entry fun admin_action(
    cap: &AdminCap,
    registry: &mut Registry,
    ctx: &TxContext,
) {
    // AdminCap 的拥有者检查通过类型系统自动完成
    // 额外检查：确保操作的是正确的注册表
    assert!(object::id(registry) == cap.registry_id, EWrongRegistry);
    // ...
}

// ❌ 坏的做法：依赖地址检查（容易被绕过）
public entry fun admin_action_bad(
    registry: &mut Registry,
    ctx: &TxContext,
) {
    assert!(tx_context::sender(ctx) == ADMIN_ADDRESS, ENotAdmin);  // 硬编码地址是反模式
}
```

### 3. 重入保护

```move
// ✅ 好的做法：先修改状态，再转账
public entry fun withdraw(
    account: &mut Account,
    ctx: &mut TxContext,
): Coin<SUI> {
    let amount = account.balance;
    assert!(amount > 0, ENoBalance);
    
    // 1. 先修改状态
    account.balance = 0;
    
    // 2. 再转账（如果失败，状态已修改，防止重入）
    coin::take(&mut account.coin, amount, ctx)
}
```

### 4. 整数溢出检查

```move
// ✅ Move 自动检查，但显式使用安全运算更好
use std::u64;

public fun safe_add(a: u64, b: u64): u64 {
    let sum = a + b;  // Move 会自动检查溢出并 abort
    sum
}

// 或者使用标准库的 saturating 运算
public fun saturating_add(a: u64, b: u64): u64 {
    if (a > MAX_U64 - b) {
        MAX_U64
    } else {
        a + b
    }
}
```

---

## 五、Gas 优化技巧

### 1. 最小化存储

```move
// ✅ 好的做法：使用紧凑的数据结构
struct CompactTask has key, store {
    id: UID,
    // 使用 u8 而不是 u64 如果范围足够
    status: u8,  // 0, 1, 2 就足够
    priority: u8,  // 1-10
    // 使用 vector 而不是多个字段存储动态数据
    tags: vector<u8>,
}

// ❌ 坏的做法：过度使用大类型
struct BloatedTask has key, store {
    id: UID,
    status: u64,  // 浪费空间
    description: String,  // 长字符串存储在链上很贵
    metadata: vector<u8>,  // 大数据应该存在链下
}
```

### 2. 批处理操作

```move
// ✅ 好的做法：批量操作减少交易数
public entry fun batch_update(
    tasks: &mut vector<Task>,
    new_status: u8,
) {
    let len = vector::length(tasks);
    let i = 0;
    while (i < len) {
        let task = vector::borrow_mut(tasks, i);
        task.status = new_status;
        i = i + 1;
    }
}
```

### 3. 使用动态字段

```move
use sui::dynamic_field as df;

// 存储可选的元数据，不占用主对象空间
public fun add_metadata<T: store>(
    obj: &mut Object,
    key: String,
    value: T,
) {
    df::add(&mut obj.id, key, value);
}
```

---

## 六、测试模式

```move
#[test_only]
module my_module::test_helpers {
    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    // 创建测试用的 SUI
    public fun mint_sui(amount: u64, ctx: &mut TxContext): Coin<SUI> {
        coin::mint_for_testing(amount, ctx)
    }

    // 常用的测试地址
    public fun admin(): address { @0xAD }
    public fun user1(): address { @0xA1 }
    public fun user2(): address { @0xA2 }
}

#[test]
fun test_create_task() {
    use sui::test_scenario;
    
    let scenario = test_scenario::begin(admin());
    {
        // 初始化模块
        init(test_scenario::ctx(&mut scenario));
    };
    
    // 用户创建任务
    test_scenario::next_tx(&mut scenario, user1());
    {
        let reward = mint_sui(1000, test_scenario::ctx(&mut scenario));
        create_task(reward, b"Test task".to_string(), test_scenario::ctx(&mut scenario));
    };
    
    // 验证任务创建
    test_scenario::next_tx(&mut scenario, user1());
    {
        let task = test_scenario::take_shared<Task>(&scenario);
        assert!(task.reward == 1000, 0);
        test_scenario::return_shared(task);
    };
    
    test_scenario::end(scenario);
}
```

---

## 七、常见错误清单

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| `EImmBorrow` | 同时存在可变和不可变引用 | 重新设计借用逻辑 |
| `EMoveToExisting` | 尝试创建已存在的对象 | 检查对象唯一性 |
| `EInvalidCapability` | 权限不足 | 检查 Cap 传递 |
| Gas 过高 | 存储或计算过多 | 优化数据结构，批处理 |
| 状态不一致 | 异常时未清理 | 使用 assert! 提前检查 |

---

*最后更新: 2026-03-28*
