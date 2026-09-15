Spring Boot 中有大量的注解，它们极大地简化了配置和开发过程。为了方便记忆和查阅，可以将这些常用注解按**功能场景**进行分类：

---

### 一、 核心启动与配置注解

1. **`@SpringBootApplication`**
   * **作用**：Spring Boot 的核心注解，用于标注主程序类。
   * **组成**：它是一个复合注解，包含了：
     * `@SpringBootConfiguration`：底层是 `@Configuration`，声明为配置类。
     * `@EnableAutoConfiguration`：开启自动配置机制。
     * `@ComponentScan`：开启组件扫描（默认扫描当前类所在的包及子包）。

2. **`@Configuration`**
   * **作用**：声明当前类是一个配置类（相当于传统的 XML 配置文件）。

3. **`@Bean`**
   * **作用**：通常用在 `@Configuration` 类的方法上，将该方法的返回值作为一个 Bean 注册到 Spring 容器中。

---

### 二、 组件声明与注册注解（IoC）

用于将类实例化并注入到 Spring 容器中：

1. **`@Component`**：通用的 Spring 容器组件注解（任何难以归类的类均可使用）。
2. **`@Controller`**：声明在表现层（MVC 中的 Controller），用于处理 HTTP 请求并返回视图（如 JSP/Thymeleaf）。
3. **`@RestController`**：
   * **作用**：`@Controller` + `@ResponseBody` 的组合注解。
   * **用途**：专门用于构建 RESTful API，方法默认直接返回 JSON/XML 等数据，不走视图解析器。
4. **`@Service`**：声明在业务逻辑层（Service 层）。
5. **`@Repository`**：声明在持久层（DAO/Mapper 层），且具有将数据库异常转换为 Spring 数据访问异常的功能。
6. **`@Scope`**：声明 Bean 的作用域（如 `singleton` 单例、`prototype` 原型）。

---

### 三、 依赖注入注解（DI）

1. **`@Autowired`**
   * **作用**：由 Spring 提供，默认按照 **类型（byType）** 自动装配。
   * 如果存在多个同类型的 Bean，可以配合 **`@Qualifier("beanName")`** 实现按名称装配。
2. **`@Resource`**
   * **作用**：由 Java（JSR-250）提供，默认按照 **名称（byName）** 装配；若找不到，则退化为按类型装配。
3. **`@Value`**
   * **作用**：从配置文件（如 `application.yml`）中读取属性值注入到变量中。
   * 示例：`@Value("${server.port}") private int port;`

---

### 四、 Web与请求映射注解

1. **请求路径映射**：
   * **`@RequestMapping`**：通用的映射注解，可指定路径和 HTTP 方法（GET、POST 等）。
   * **快捷注解**（推荐）：
     * `@GetMapping`（获取数据）
     * `@PostMapping`（提交/创建数据）
     * `@PutMapping`（更新数据）
     * `@DeleteMapping`（删除数据）

2. **接收请求参数**：
   * **`@PathVariable`**：获取 URL 路径中的动态参数。
     * 示例：`/users/{id}` -> `@PathVariable("id") Long id`
   * **`@RequestParam`**：获取 Query 参数（`?name=abc`）或表单数据。
     * 示例：`@RequestParam(value = "name", required = false) String name`
   * **`@RequestBody`**：将 HTTP 请求体中的 **JSON/XML 数据反序列化为 Java 对象**（通常配合 POST/PUT 使用）。
   * **`@RequestHeader`**：获取 HTTP 请求头的值。
   * **`@CookieValue`**：获取 Cookie 的值。

---

### 五、 读取配置注解

1. **`@ConfigurationProperties`**
   * **作用**：将配置文件（yml/properties）中的一组属性批量映射绑定到一个 JavaBean 上。
   * 示例：`@ConfigurationProperties(prefix = "mypost.datasource")`
2. **`@PropertySource`**
   * **作用**：加载指定的非全局配置文件（例如 `custom.properties`）。

---

### 六、 异常处理与拦截

1. **`@ControllerAdvice` / `@RestControllerAdvice`**
   * **作用**：定义全局异常处理类。`@RestControllerAdvice` 返回 JSON 数据。
2. **`@ExceptionHandler`**
   * **作用**：声明在方法上，指定该方法用于处理某类特定的异常（如 `@ExceptionHandler(NullPointerException.class)`）。

---

### 七、 条件注解（Spring Boot 自动装配的核心）

根据特定条件决定是否装配 Bean（常用于二次开发 Starter）：
* **`@ConditionalOnClass`**：当类路径下存在指定类时生效。
* **`@ConditionalOnMissingClass`**：当类路径下没有指定类时生效。
* **`@ConditionalOnBean`**：容器中存在指定 Bean 时生效。
* **`@ConditionalOnMissingBean`**：容器中没有指定 Bean 时生效（常用于提供默认实现）。
* **`@ConditionalOnProperty`**：配置文件中指定的属性有对应值时生效。

---

### 八、 高级功能（事务、异步、定时任务）

1. **`@Transactional`**：声明式事务管理，加在方法或类上，保证操作的原子性。
2. **`@Async`**：声明该方法为异步调用（需在启动类上加 `@EnableAsync` 开启）。
3. **`@Scheduled`**：用于定时任务（需在启动类上加 `@EnableScheduling` 开启，支持 cron 表达式）。

---

### 九、 补充：常搭配的 Lombok 注解（非 Spring 官方但极常用）

* **`@Data`**：自动生成 Getter、Setter、toString、equals、hashCode 等。
* **`@Slf4j`**：自动生成日志对象 `log`，无需手动创建 `LoggerFactory.getLogger(...)`。
* **`@AllArgsConstructor` / `@NoArgsConstructor`**：自动生成全参/无参构造函数。
* **`@RequiredArgsConstructor`**：配合 `final` 关键字，是官方**最推荐的依赖注入方式**（构造器注入）。