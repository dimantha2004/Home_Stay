# SmartStay Hotel Booking System

CI6115 Programming III – Patterns and Algorithms · Student ID **358842**

In the UML class diagrams every class name is prefixed with the student ID, for example `358842Guest`, `358842Room`, `358842BookingController`. The prefix belongs to the UML diagrams (as the brief requires). The Java source code uses ordinary class names (`Guest`, `Room`, `BookingController`).

A JavaFX desktop application for hotel room management, guest registration, room reservations and invoicing, backed by MySQL.

## Requirements

| Software | Version used |
|---|---|
| JDK | 17 or newer (developed with JDK 21, compiled with `--release 17`) |
| Apache Maven | 3.9 or newer (IntelliJ IDEA's bundled Maven also works) |
| MySQL Server | 8.0 (CHECK constraints need 8.0.16 or newer) |
| IDE (optional) | IntelliJ IDEA |

JavaFX, the MySQL JDBC driver and JUnit are downloaded by Maven. No separate JavaFX SDK is needed.

## 1. Create the database

From the project folder:

```
mysql -u root -p < database/schema.sql
mysql -u root -p smartstay < database/sample-data.sql
```

`schema.sql` drops and recreates the `smartstay` database. Run both scripts again whenever you want to return to the original sample data.

The sample data's booking dates are relative to the current date, so the demonstration data is always in the future.

## 2. Configure the connection

Edit `src/main/resources/config/db.properties`:

```
db.url=jdbc:mysql://localhost:3306/smartstay?serverTimezone=Asia/Colombo
db.username=root
db.password=hello123
```

## 3. Run the application

**Command line:**

```
mvn javafx:run
```

**IntelliJ IDEA:**

1. File → Open → select this folder. It imports as a Maven project.
2. Run `com.smartstay.Launcher`, or use the Maven tool window: Plugins → javafx → `javafx:run`.

**Without Maven or an IDE (Windows):**

Double-click `run.bat`. It starts the pre-built jar in `dist/` with the bundled libraries in `dist/lib/`. It needs Java 17+ on the PATH and the database from step 1.

The database settings are compiled into the jar. If you change `db.properties`, rebuild it with `mvn package` and copy `target/smartstay-hotel-booking-1.0.0.jar` into `dist/`.

**Logins:**

| Role | How to sign in |
|---|---|
| Administrator | username `admin`, password `Admin@123` |
| Guest | click **Continue as guest** (no account needed) |

If MySQL is not reachable, the application shows a "Database unavailable" message and exits.

## 4. Run the tests

| Tests | Command | Notes |
|---|---|---|
| Unit + integration (JUnit 5, 46 tests) | `mvn test` | The database tests are skipped automatically if MySQL is not running |
| System test cases (94 cases) | see below | **Modifies the database**: reload the sample data afterwards |

System test runner command, run from the project folder (replace the jar path with yours):

```
mvn compile
java -cp "target/classes;<path-to>/mysql-connector-j-8.4.0.jar" documentation/test-evidence/TestCaseRunner.java
```

The runner rewrites `documentation/test-cases/358842-system-test-results.md` with the actual results of the run.

## 5. Project structure

```
pom.xml                         Maven build (Java 17, JavaFX 21, MySQL Connector/J, JUnit 5)
run.bat                         starts the pre-built application (no Maven needed)
dist/                           pre-built jar + runtime libraries (JavaFX, MySQL Connector/J)
database/                       schema.sql, sample-data.sql
uml/                            PlantUML sources (*.puml) and rendered class diagrams (*.png, *.svg)
src/main/java/com/smartstay/
    358842Launcher, 358842SmartStayApp      entry point and JavaFX application
    model/        entities and enums (Person, Guest, Administrator, Room, RoomType, Reservation, Invoice)
    billing/      invoice calculator and discount strategies
    dao/          JDBC data access (generic DAO + template method)
    service/      business rules, algorithms, transactions
    config/       database singleton, booking policy constants
    exception/    validation and data-access exceptions
    controller/   JavaFX controllers (one per FXML screen)
    util/         shared UI helpers
src/main/resources/
    fxml/         screen layouts
    css/          application stylesheet
    config/       db.properties
src/test/java/                  JUnit tests
documentation/
    design-notes.md             design decisions, assumptions, rationale
    test-cases/                 test case document with actual results
    test-evidence/              test runners and execution logs
    screenshots/                application screenshots used in the report and tests
    report/                     coursework report (HTML source, build script, PDF)
```

## 6. Assumptions

The full list is in `documentation/design-notes.md`. The main ones:

- **Room capacity:** Standard 2, Deluxe 2, Suite 3, Family Suite 4, with a maximum of capacity + 2 guests. These values are configurable in the `room_types` table.
- **Extra-guest charge:** charged per extra guest, per night.
- **Discount:** the 12% discount for 5 or more nights applies to the base room charge only.
- **Tax:** applied to base + extra guest charges − discount.
- **Refund:** if the LKR 10,000 advance exceeds the bill, the invoice shows a refund due.
- **24-hour rule:** check-in time is 14:00. Changes and cancellations close 24 hours before that.
