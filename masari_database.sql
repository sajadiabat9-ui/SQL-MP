/* =====================================================================
   MASARI DATABASE  -  Microsoft SQL Server (T-SQL)
   A beginner-friendly database for the Masari website.

   HOW TO RUN
   1. Open SQL Server Management Studio (SSMS) and connect to your server.
   2. File > Open > File... and choose this script.
   3. Press F5 (Execute). The script can be run again and again: it deletes the old
      MasariDB database and builds it from zero.
   4. Run the sections one by one later to learn (each PART has comments).

   NOTES FOR A BEGINNER
   * GO is not SQL. It only tells SSMS "send everything above as one batch".
   * N'text' means Unicode text. We use it so Arabic letters are saved correctly.
   * Every table has an ID column that counts by itself: INT IDENTITY(1,1) PRIMARY KEY.
   * Names: tables are plural (Users), IDs end with ID (UserID), prefixes: vw_ = view,
     fn_ = function, usp_ = stored procedure, trg_ = trigger, IX_ = index.

   CONTENTS
   PART 1  Create the database
   PART 2  Create the tables (relations, keys and constraints)
   PART 3  Insert the Masari data (majors, universities, users, quiz ...)
   PART 4  SQL Day 01: CREATE / ALTER / DROP / TRUNCATE, SELECT / INSERT / UPDATE / DELETE, aggregation
   PART 5  SQL Day 02: relations, joins, WHERE / GROUP BY / HAVING, indexes, views, functions,
           stored procedures, subqueries, triggers, normalization
   ===================================================================== */

/* =====================================================================
   PART 1 : CREATE DATABASE
   ===================================================================== */
USE master;
GO

-- DROP DATABASE deletes a whole database. IF EXISTS avoids an error when it is not there yet.
DROP DATABASE IF EXISTS MasariDB;
GO

CREATE DATABASE MasariDB;
GO

USE MasariDB;
GO

/* =====================================================================
   PART 2 : CREATE TABLES
   Constraints used:  PRIMARY KEY (unique id of a row)   NOT NULL (value is required)
                      UNIQUE (no duplicates)             FOREIGN KEY (points to a row in another table)
   Data types used:   INT (whole number)   DECIMAL(4,1) (number with one decimal, like 87.5)
                      NVARCHAR(n) (text up to n letters, Unicode)   CHAR(n) (text with fixed length)
                      BIT (0 or 1, like false / true)   DATETIME (date and time)
   ===================================================================== */

/* ---- 2.1 Small "lookup" tables: other tables point to them ---- */

-- The three plans of the site (Upgrade page)
CREATE TABLE Plans (
    PlanID      INT IDENTITY(1,1) PRIMARY KEY,
    PlanName    NVARCHAR(30)  NOT NULL UNIQUE,
    PriceJOD    DECIMAL(5,2)  NOT NULL,
    Description NVARCHAR(300) NOT NULL
);

-- Jordanian cities (register, profile and university pages)
CREATE TABLE Cities (
    CityID     INT IDENTITY(1,1) PRIMARY KEY,
    CityName   NVARCHAR(50) NOT NULL UNIQUE,
    CityNameAr NVARCHAR(50) NOT NULL
);

-- Tawjihi streams (Scientific, Literary, Other)
CREATE TABLE Streams (
    StreamID   INT IDENTITY(1,1) PRIMARY KEY,
    StreamName NVARCHAR(30) NOT NULL UNIQUE
);

/* ---- 2.2 Content tables: majors, skills, universities ---- */

-- Majors (Top majors, Major details, Compare)
CREATE TABLE Majors (
    MajorID        INT IDENTITY(1,1) PRIMARY KEY,
    MajorName      NVARCHAR(60)  NOT NULL UNIQUE,
    MajorNameAr    NVARCHAR(60)  NOT NULL,
    Description    NVARCHAR(300) NOT NULL,
    DescriptionAr  NVARCHAR(300) NOT NULL,
    MinAverage     DECIMAL(4,1)  NOT NULL,   -- minimum Tawjihi average, like 80.0
    StudyYears     INT           NOT NULL,
    ScientificOnly BIT           NOT NULL,   -- 1 = only the Scientific stream can enter
    InterestCode   CHAR(3)       NOT NULL,   -- 3 RIASEC letters, like IRC
    IconName       NVARCHAR(30)  NOT NULL,
    IsVisible      BIT           NOT NULL,   -- the admin can hide a major
    ViewsCount     INT           NOT NULL
);

-- Skills (Skills Gap page). RiasecType says which kind of work the skill belongs to.
CREATE TABLE Skills (
    SkillID     INT IDENTITY(1,1) PRIMARY KEY,
    SkillName   NVARCHAR(60) NOT NULL UNIQUE,
    SkillNameAr NVARCHAR(60) NOT NULL,
    RiasecType  CHAR(1)      NOT NULL
);

-- Universities (University Explorer).  ONE city has MANY universities (one-to-many).
CREATE TABLE Universities (
    UniversityID     INT IDENTITY(1,1) PRIMARY KEY,
    UniversityName   NVARCHAR(100) NOT NULL UNIQUE,
    UniversityNameAr NVARCHAR(100) NOT NULL,
    CityID           INT           NOT NULL FOREIGN KEY REFERENCES Cities(CityID),
    UniType          NVARCHAR(10)  NOT NULL,   -- Public or Private
    FoundedYear      INT           NOT NULL,
    LogoKey          NVARCHAR(10)  NOT NULL    -- name of the logo file in assets/logos
);

-- MANY-TO-MANY: a university offers many majors, and a major is offered by many universities.
-- We need a third "link" table. Its primary key is made of TWO columns.
CREATE TABLE UniversityMajors (
    UniversityID INT NOT NULL FOREIGN KEY REFERENCES Universities(UniversityID),
    MajorID      INT NOT NULL FOREIGN KEY REFERENCES Majors(MajorID),
    PRIMARY KEY (UniversityID, MajorID)
);

-- Campus Tour spots. ONE university has MANY spots (one-to-many).
CREATE TABLE CampusSpots (
    SpotID        INT IDENTITY(1,1) PRIMARY KEY,
    UniversityID  INT           NOT NULL FOREIGN KEY REFERENCES Universities(UniversityID),
    SpotName      NVARCHAR(60)  NOT NULL,
    MapQuery      NVARCHAR(200) NOT NULL,    -- text used to search Google Maps
    StreetViewUrl NVARCHAR(600) NULL         -- Google embed link (empty until you add it)
);

-- MANY-TO-MANY: a major needs many skills, and a skill is used by many majors.
CREATE TABLE MajorSkills (
    MajorID INT NOT NULL FOREIGN KEY REFERENCES Majors(MajorID),
    SkillID INT NOT NULL FOREIGN KEY REFERENCES Skills(SkillID),
    PRIMARY KEY (MajorID, SkillID)
);

-- ONE-TO-MANY: one major has many careers.
CREATE TABLE Careers (
    CareerID     INT IDENTITY(1,1) PRIMARY KEY,
    MajorID      INT          NOT NULL FOREIGN KEY REFERENCES Majors(MajorID),
    CareerName   NVARCHAR(80) NOT NULL,
    CareerNameAr NVARCHAR(80) NOT NULL
);

-- Try a Major quiz questions. ONE major has MANY questions, and each question tests ONE skill.
CREATE TABLE QuizQuestions (
    QuestionID   INT IDENTITY(1,1) PRIMARY KEY,
    MajorID      INT           NOT NULL FOREIGN KEY REFERENCES Majors(MajorID),
    SkillID      INT           NOT NULL FOREIGN KEY REFERENCES Skills(SkillID),
    QuestionText NVARCHAR(300) NOT NULL,
    RightAnswer  NVARCHAR(200) NOT NULL,
    WrongAnswer1 NVARCHAR(200) NOT NULL,
    WrongAnswer2 NVARCHAR(200) NOT NULL,
    Explanation  NVARCHAR(300) NOT NULL
);

/* ---- 2.3 People and their results ---- */

-- Users: students and the administrator (Register, Login, Profile, Admin > Users)
-- ONE plan has MANY users. ONE city has MANY users. ONE major can be chosen by MANY users.
CREATE TABLE Users (
    UserID        INT IDENTITY(1,1) PRIMARY KEY,
    FullName      NVARCHAR(100) NOT NULL,
    Email         NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash  NVARCHAR(200) NOT NULL,
    CityID        INT           NULL FOREIGN KEY REFERENCES Cities(CityID),
    AvatarNo      INT           NOT NULL,     -- 0 to 5
    CareerGoal    NVARCHAR(150) NULL,
    PlanID        INT           NOT NULL FOREIGN KEY REFERENCES Plans(PlanID),
    ChosenMajorID INT           NULL FOREIGN KEY REFERENCES Majors(MajorID),
    Role          NVARCHAR(20)  NOT NULL,     -- student or admin
    Status        NVARCHAR(20)  NOT NULL,     -- active or suspended
    CreatedAt     DATETIME      NOT NULL
);

-- ONE-TO-ONE: every student has ONE Tawjihi result.
-- The primary key is also the foreign key, so a user can have only one row here.
CREATE TABLE TawjihiResults (
    UserID   INT          NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES Users(UserID),
    Average  DECIMAL(4,1) NOT NULL,
    StreamID INT          NOT NULL FOREIGN KEY REFERENCES Streams(StreamID),
    SavedAt  DATETIME     NOT NULL
);

-- Interest test result: 6 rows per student, one for each letter R, I, A, S, E, C.
-- (We use rows instead of 6 columns: this is the "First Normal Form" idea, see PART 5.10)
CREATE TABLE InterestScores (
    UserID INT     NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    Letter CHAR(1) NOT NULL,
    Score  INT     NOT NULL,                  -- 2 to 10
    PRIMARY KEY (UserID, Letter)
);

-- Try a Major answers: one row for every skill question the student answered
CREATE TABLE QuizResults (
    QuizResultID INT IDENTITY(1,1) PRIMARY KEY,
    UserID       INT      NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    MajorID      INT      NOT NULL FOREIGN KEY REFERENCES Majors(MajorID),
    SkillID      INT      NOT NULL FOREIGN KEY REFERENCES Skills(SkillID),
    IsCorrect    BIT      NOT NULL,           -- 1 = correct, 0 = wrong
    TakenAt      DATETIME NOT NULL
);

/* ---- 2.4 Money, messages and admin ---- */

-- History of plans a user paid for (Upgrade page, Admin > Plans and revenue)
CREATE TABLE Subscriptions (
    SubscriptionID INT IDENTITY(1,1) PRIMARY KEY,
    UserID         INT          NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    PlanID         INT          NOT NULL FOREIGN KEY REFERENCES Plans(PlanID),
    StartDate      DATETIME     NOT NULL,
    PricePaid      DECIMAL(5,2) NOT NULL
);

-- Messages from the Contact page (visitors do not need an account)
CREATE TABLE Messages (
    MessageID   INT IDENTITY(1,1) PRIMARY KEY,
    FullName    NVARCHAR(100)  NOT NULL,
    Email       NVARCHAR(150)  NOT NULL,
    Subject     NVARCHAR(80)   NOT NULL,
    MessageText NVARCHAR(1000) NOT NULL,
    Status      NVARCHAR(10)   NOT NULL,      -- new, read or replied
    SentAt      DATETIME       NOT NULL
);

-- Site settings (Admin > Settings). Example: how many majors the free plan can see.
CREATE TABLE Settings (
    SettingID    INT IDENTITY(1,1) PRIMARY KEY,
    SettingKey   NVARCHAR(50)  NOT NULL UNIQUE,
    SettingValue NVARCHAR(200) NOT NULL
);

-- Activity feed on the admin dashboard
CREATE TABLE ActivityLog (
    LogID      INT IDENTITY(1,1) PRIMARY KEY,
    UserID     INT           NULL FOREIGN KEY REFERENCES Users(UserID),
    ActionText NVARCHAR(200) NOT NULL,
    CreatedAt  DATETIME      NOT NULL
);
GO

/* =====================================================================
   PART 3 : INSERT THE MASARI DATA
   INSERT INTO table (columns) VALUES (values), (values), ... ;
   The IDs are given by IDENTITY in the same order as the rows below,
   so the first row of each table has ID 1, the second ID 2, and so on.
   ===================================================================== */

-- Plans (PlanID 1 = Free, 2 = Premium, 3 = Campus Pass)
INSERT INTO Plans (PlanName, PriceJOD, Description) VALUES
    (N'Free', 0.00, N'Score, interest test, top 3 majors, universities, compare, career path, skills gap, advisor'),
    (N'Premium', 4.99, N'Everything in Free + all 10 majors, What If, Career Plan, full report'),
    (N'Campus Pass', 9.99, N'Everything in Premium + Campus Tour 360');

-- Cities (CityID follows this order: 1=Amman, 2=Irbid, 3=Zarqa, 4=Mafraq, 5=Karak, 6=Ma'an, 7=Salt, 8=Tafila, 9=Jerash, 10=Balqa, 11=Ajloun, 12=Madaba, 13=Aqaba)
INSERT INTO Cities (CityName, CityNameAr) VALUES
    (N'Amman', N'عمّان'),
    (N'Irbid', N'إربد'),
    (N'Zarqa', N'الزرقاء'),
    (N'Mafraq', N'المفرق'),
    (N'Karak', N'الكرك'),
    (N'Ma''an', N'معان'),
    (N'Salt', N'السلط'),
    (N'Tafila', N'الطفيلة'),
    (N'Jerash', N'جرش'),
    (N'Balqa', N'البلقاء'),
    (N'Ajloun', N'عجلون'),
    (N'Madaba', N'مادبا'),
    (N'Aqaba', N'العقبة');

-- Streams (1 = Scientific, 2 = Literary, 3 = Other)
INSERT INTO Streams (StreamName) VALUES
    (N'Scientific'),
    (N'Literary'),
    (N'Other');

-- Majors (MajorID follows this order: 1=Computer Science, 2=Cybersecurity, 3=Artificial Intelligence, 4=Medicine, 5=Pharmacy, 6=Civil Engineering, 7=Electrical Engineering, 8=Nursing, 9=Business Administration, 10=Accounting, 11=Graphic Design, 12=Law, 13=Psychology)
INSERT INTO Majors (MajorName, MajorNameAr, Description, DescriptionAr, MinAverage, StudyYears, ScientificOnly, InterestCode, IconName, IsVisible, ViewsCount) VALUES
    (N'Computer Science', N'علوم الحاسوب', N'Design and build software, apps and systems.', N'تصميم وبناء البرمجيات والتطبيقات والأنظمة.', 80, 4, 1, 'IRC', 'code', 1, 420),
    (N'Cybersecurity', N'الأمن السيبراني', N'Protect systems and data from attacks.', N'حماية الأنظمة والبيانات من الهجمات.', 78, 4, 1, 'IRC', 'shield', 1, 310),
    (N'Artificial Intelligence', N'الذكاء الاصطناعي', N'Teach computers to learn from data.', N'تعليم الحواسيب أن تتعلّم من البيانات.', 85, 4, 1, 'IRC', 'cpu', 1, 290),
    (N'Medicine', N'الطب', N'Diagnose, treat and prevent illness.', N'تشخيص الأمراض وعلاجها والوقاية منها.', 90, 6, 1, 'ISA', 'stethoscope', 1, 380),
    (N'Pharmacy', N'الصيدلة', N'Prepare medicines and advise patients on safe use.', N'تحضير الأدوية ونصح المرضى باستخدامها الآمن.', 85, 5, 1, 'ISC', 'pill', 1, 150),
    (N'Civil Engineering', N'الهندسة المدنية', N'Design and build roads, bridges and buildings.', N'تصميم وبناء الطرق والجسور والمباني.', 75, 5, 1, 'RIC', 'hardhat', 1, 170),
    (N'Electrical Engineering', N'الهندسة الكهربائية', N'Work with power, electronics and communication systems.', N'العمل مع الطاقة والإلكترونيات وأنظمة الاتصالات.', 78, 5, 1, 'RIC', 'zap', 1, 140),
    (N'Nursing', N'التمريض', N'Care for patients and support medical teams.', N'رعاية المرضى ودعم الفرق الطبية.', 65, 4, 1, 'SIC', 'heart', 1, 160),
    (N'Business Administration', N'إدارة الأعمال', N'Plan, lead and grow organizations.', N'التخطيط للمؤسسات وقيادتها وتنميتها.', 60, 4, 0, 'ECS', 'briefcase', 1, 260),
    (N'Accounting', N'المحاسبة', N'Record, check and report financial information.', N'تسجيل المعلومات المالية ومراجعتها والإبلاغ عنها.', 62, 4, 0, 'CER', 'calculator', 1, 120),
    (N'Graphic Design', N'التصميم الغرافيكي', N'Communicate ideas through images and layout.', N'إيصال الأفكار عبر الصور والتخطيط.', 60, 4, 0, 'AER', 'palette', 1, 200),
    (N'Law', N'القانون', N'Study laws and represent people and organizations.', N'دراسة القوانين وتمثيل الأفراد والمؤسسات.', 70, 4, 0, 'ESA', 'gavel', 1, 130),
    (N'Psychology', N'علم النفس', N'Understand behavior and support mental well-being.', N'فهم السلوك ودعم الصحة النفسية.', 65, 4, 0, 'SIA', 'brain', 1, 180);

-- Users (UserID 1 = Lina Haddad, the demo student. UserID 13 = the administrator)
-- PasswordHash is only a placeholder: a real backend stores a secure hash, never the password itself.
INSERT INTO Users (FullName, Email, PasswordHash, CityID, AvatarNo, CareerGoal, PlanID, ChosenMajorID, Role, Status, CreatedAt) VALUES
    (N'Lina Haddad', N'demo@masari.jo', N'demo-hash-not-a-real-password', 1, 1, NULL, 1, 1, N'student', N'active', '2026-10-02T10:00:00'),
    (N'Omar Khalil', N'omar.k@mail.com', N'demo-hash-not-a-real-password', 2, 2, NULL, 2, 4, N'student', N'active', '2026-09-21T10:00:00'),
    (N'Sara Nasser', N'sara.n@mail.com', N'demo-hash-not-a-real-password', 3, 3, NULL, 3, 6, N'student', N'active', '2026-09-14T10:00:00'),
    (N'Yazan Odeh', N'yazan.o@mail.com', N'demo-hash-not-a-real-password', 1, 4, NULL, 2, 2, N'student', N'active', '2026-08-30T10:00:00'),
    (N'Rana Mahmoud', N'rana.m@mail.com', N'demo-hash-not-a-real-password', 5, 5, NULL, 1, 13, N'student', N'active', '2026-08-18T10:00:00'),
    (N'Ahmad Saleh', N'ahmad.s@mail.com', N'demo-hash-not-a-real-password', 13, 0, NULL, 1, 9, N'student', N'suspended', '2026-08-02T10:00:00'),
    (N'Dana Qasem', N'dana.q@mail.com', N'demo-hash-not-a-real-password', 12, 1, NULL, 2, 11, N'student', N'active', '2026-07-25T10:00:00'),
    (N'Khaled Abu-Zaid', N'khaled.a@mail.com', N'demo-hash-not-a-real-password', 7, 2, NULL, 1, 12, N'student', N'active', '2026-07-11T10:00:00'),
    (N'Hiba Alami', N'hiba.a@mail.com', N'demo-hash-not-a-real-password', 1, 3, NULL, 3, 3, N'student', N'active', '2026-06-29T10:00:00'),
    (N'Tariq Jaber', N'tariq.j@mail.com', N'demo-hash-not-a-real-password', 9, 4, NULL, 1, 7, N'student', N'active', '2026-06-12T10:00:00'),
    (N'Noor Hamdan', N'noor.h@mail.com', N'demo-hash-not-a-real-password', 2, 5, NULL, 2, 8, N'student', N'active', '2026-05-20T10:00:00'),
    (N'Mahmoud Daoud', N'mahmoud.d@mail.com', N'demo-hash-not-a-real-password', 1, 0, NULL, 1, 10, N'student', N'active', '2026-05-04T10:00:00'),
    (N'Administrator', N'admin@masari.jo', N'demo-hash-not-a-real-password', 1, 3, NULL, 1, NULL, N'admin', N'active', '2026-01-01T09:00:00');

-- Tawjihi results: one row per student (one-to-one with Users)
INSERT INTO TawjihiResults (UserID, Average, StreamID, SavedAt) VALUES
    (1, 87, 1, '2026-10-02T10:05:00'),
    (2, 91, 1, '2026-09-21T10:05:00'),
    (3, 84, 1, '2026-09-14T10:05:00'),
    (4, 79, 1, '2026-08-30T10:05:00'),
    (5, 72, 2, '2026-08-18T10:05:00'),
    (6, 66, 2, '2026-08-02T10:05:00'),
    (7, 88, 1, '2026-07-25T10:05:00'),
    (8, 69, 2, '2026-07-11T10:05:00'),
    (9, 93, 1, '2026-06-29T10:05:00'),
    (10, 74, 1, '2026-06-12T10:05:00'),
    (11, 82, 1, '2026-05-20T10:05:00'),
    (12, 63, 3, '2026-05-04T10:05:00');

-- Interest test scores: 6 rows per student, one for each RIASEC letter (score from 2 to 10)
INSERT INTO InterestScores (UserID, Letter, Score) VALUES
    (1, 'R', 6),
    (1, 'I', 9),
    (1, 'A', 4),
    (1, 'S', 5),
    (1, 'E', 6),
    (1, 'C', 7),
    (2, 'R', 4),
    (2, 'I', 9),
    (2, 'A', 7),
    (2, 'S', 8),
    (2, 'E', 4),
    (2, 'C', 4),
    (3, 'R', 9),
    (3, 'I', 8),
    (3, 'A', 4),
    (3, 'S', 4),
    (3, 'E', 4),
    (3, 'C', 7),
    (4, 'R', 8),
    (4, 'I', 9),
    (4, 'A', 4),
    (4, 'S', 4),
    (4, 'E', 4),
    (4, 'C', 7),
    (5, 'R', 4),
    (5, 'I', 8),
    (5, 'A', 7),
    (5, 'S', 9),
    (5, 'E', 4),
    (5, 'C', 4),
    (6, 'R', 4),
    (6, 'I', 4),
    (6, 'A', 4),
    (6, 'S', 7),
    (6, 'E', 9),
    (6, 'C', 8),
    (7, 'R', 7),
    (7, 'I', 8),
    (7, 'A', 9),
    (7, 'S', 4),
    (7, 'E', 4),
    (7, 'C', 4),
    (8, 'R', 4),
    (8, 'I', 4),
    (8, 'A', 7),
    (8, 'S', 8),
    (8, 'E', 9),
    (8, 'C', 4),
    (9, 'R', 8),
    (9, 'I', 9),
    (9, 'A', 4),
    (9, 'S', 4),
    (9, 'E', 4),
    (9, 'C', 7),
    (10, 'R', 9),
    (10, 'I', 8),
    (10, 'A', 4),
    (10, 'S', 4),
    (10, 'E', 4),
    (10, 'C', 7),
    (11, 'R', 4),
    (11, 'I', 8),
    (11, 'A', 4),
    (11, 'S', 9),
    (11, 'E', 4),
    (11, 'C', 7),
    (12, 'R', 7),
    (12, 'I', 4),
    (12, 'A', 4),
    (12, 'S', 4),
    (12, 'E', 8),
    (12, 'C', 9);

-- Universities (UniversityID follows this order: 1=uj, 2=just, 3=yu, 4=hu, 5=mu, 6=abu, 7=ahu, 8=bau, 9=ttu, 10=gju, 11=psut, 12=aau, 13=ahli, 14=phi, 15=asu, 16=zu, 17=zay, 18=meu, 19=isr, 20=jad, 21=jer, 22=pet)
INSERT INTO Universities (UniversityName, UniversityNameAr, CityID, UniType, FoundedYear, LogoKey) VALUES
    (N'University of Jordan', N'الجامعة الأردنية', 1, N'Public', 1962, 'uj'),
    (N'Jordan University of Science and Technology', N'جامعة العلوم والتكنولوجيا الأردنية', 2, N'Public', 1986, 'just'),
    (N'Yarmouk University', N'جامعة اليرموك', 2, N'Public', 1976, 'yu'),
    (N'Hashemite University', N'الجامعة الهاشمية', 3, N'Public', 1991, 'hu'),
    (N'Mutah University', N'جامعة مؤتة', 5, N'Public', 1981, 'mu'),
    (N'Al al-Bayt University', N'جامعة آل البيت', 4, N'Public', 1992, 'abu'),
    (N'Al-Hussein Bin Talal University', N'جامعة الحسين بن طلال', 6, N'Public', 1999, 'ahu'),
    (N'Al-Balqa Applied University', N'جامعة البلقاء التطبيقية', 7, N'Public', 1997, 'bau'),
    (N'Tafila Technical University', N'جامعة الطفيلة التقنية', 8, N'Public', 2005, 'ttu'),
    (N'German Jordanian University', N'الجامعة الألمانية الأردنية', 1, N'Public', 2005, 'gju'),
    (N'Princess Sumaya University for Technology', N'جامعة الأميرة سمية للتكنولوجيا', 1, N'Private', 1991, 'psut'),
    (N'Amman Arab University', N'جامعة عمّان العربية', 1, N'Private', 1999, 'aau'),
    (N'Al-Ahliyya Amman University', N'جامعة عمّان الأهلية', 1, N'Private', 1990, 'ahli'),
    (N'Philadelphia University', N'جامعة فيلادلفيا', 1, N'Private', 1989, 'phi'),
    (N'Applied Science Private University', N'جامعة العلوم التطبيقية الخاصة', 1, N'Private', 1991, 'asu'),
    (N'Zarqa University', N'جامعة الزرقاء', 3, N'Private', 1994, 'zu'),
    (N'Al-Zaytoonah University of Jordan', N'جامعة الزيتونة الأردنية', 1, N'Private', 1993, 'zay'),
    (N'Middle East University', N'جامعة الشرق الأوسط', 1, N'Private', 2005, 'meu'),
    (N'Isra University', N'جامعة الإسراء', 1, N'Private', 1990, 'isr'),
    (N'Jadara University', N'جامعة جدارا', 2, N'Private', 2007, 'jad'),
    (N'Jerash University', N'جامعة جرش', 9, N'Private', 1993, 'jer'),
    (N'Petra University', N'جامعة البترا', 1, N'Private', 1991, 'pet');

-- Which university offers which major (many-to-many link table)
INSERT INTO UniversityMajors (UniversityID, MajorID) VALUES
    (1, 1),
    (2, 1),
    (11, 1),
    (10, 1),
    (4, 1),
    (6, 1),
    (7, 1),
    (8, 1),
    (16, 1),
    (14, 1),
    (15, 1),
    (17, 1),
    (18, 1),
    (13, 1),
    (22, 1),
    (2, 2),
    (11, 2),
    (4, 2),
    (10, 2),
    (16, 2),
    (14, 2),
    (15, 2),
    (18, 2),
    (19, 2),
    (11, 3),
    (10, 3),
    (2, 3),
    (1, 3),
    (14, 3),
    (15, 3),
    (16, 3),
    (1, 4),
    (2, 4),
    (3, 4),
    (4, 4),
    (5, 4),
    (1, 5),
    (2, 5),
    (4, 5),
    (12, 5),
    (14, 5),
    (17, 5),
    (15, 5),
    (16, 5),
    (21, 5),
    (19, 5),
    (13, 5),
    (22, 5),
    (1, 6),
    (2, 6),
    (3, 6),
    (4, 6),
    (5, 6),
    (6, 6),
    (7, 6),
    (8, 6),
    (9, 6),
    (14, 6),
    (17, 6),
    (15, 6),
    (19, 6),
    (13, 6),
    (2, 7),
    (1, 7),
    (4, 7),
    (10, 7),
    (5, 7),
    (6, 7),
    (7, 7),
    (8, 7),
    (9, 7),
    (14, 7),
    (17, 7),
    (15, 7),
    (13, 7),
    (1, 8),
    (2, 8),
    (4, 8),
    (5, 8),
    (12, 8),
    (6, 8),
    (7, 8),
    (8, 8),
    (17, 8),
    (15, 8),
    (16, 8),
    (13, 8),
    (20, 8),
    (1, 9),
    (3, 9),
    (4, 9),
    (12, 9),
    (11, 9),
    (6, 9),
    (7, 9),
    (8, 9),
    (14, 9),
    (17, 9),
    (15, 9),
    (16, 9),
    (18, 9),
    (20, 9),
    (13, 9),
    (21, 9),
    (9, 9),
    (22, 9),
    (1, 10),
    (3, 10),
    (4, 10),
    (12, 10),
    (5, 10),
    (6, 10),
    (7, 10),
    (8, 10),
    (14, 10),
    (17, 10),
    (15, 10),
    (16, 10),
    (18, 10),
    (20, 10),
    (21, 10),
    (13, 10),
    (22, 10),
    (11, 11),
    (12, 11),
    (3, 11),
    (4, 11),
    (14, 11),
    (17, 11),
    (15, 11),
    (16, 11),
    (18, 11),
    (13, 11),
    (21, 11),
    (1, 12),
    (3, 12),
    (5, 12),
    (12, 12),
    (6, 12),
    (7, 12),
    (14, 12),
    (17, 12),
    (15, 12),
    (16, 12),
    (18, 12),
    (21, 12),
    (20, 12),
    (13, 12),
    (1, 13),
    (3, 13),
    (4, 13),
    (5, 13),
    (6, 13),
    (7, 13),
    (8, 13),
    (14, 13),
    (17, 13),
    (15, 13),
    (16, 13),
    (18, 13),
    (13, 13),
    (21, 13);

-- Campus tour spots of the University of Jordan. StreetViewUrl is empty until you paste a Google embed link.
INSERT INTO CampusSpots (UniversityID, SpotName, MapQuery, StreetViewUrl) VALUES
    (1, N'Main Gate', N'University of Jordan Main Gate, Amman', NULL),
    (1, N'Central Library', N'University of Jordan Library, Amman', NULL),
    (1, N'Faculty Building', N'Faculty of Engineering, University of Jordan, Amman', NULL),
    (1, N'Cafeteria and Plaza', N'University of Jordan Cafeteria, Amman', NULL),
    (1, N'Sports Field', N'University of Jordan Stadium, Amman', NULL);

-- Skills (RiasecType = the kind of work the skill belongs to)
INSERT INTO Skills (SkillName, SkillNameAr, RiasecType) VALUES
    (N'Programming', N'البرمجة', 'I'),
    (N'Problem solving', N'حل المشكلات', 'I'),
    (N'Algorithms', N'الخوارزميات', 'I'),
    (N'Databases', N'قواعد البيانات', 'C'),
    (N'Networking', N'الشبكات', 'R'),
    (N'Security basics', N'أساسيات الأمن', 'I'),
    (N'Linux', N'لينكس', 'R'),
    (N'Risk analysis', N'تحليل المخاطر', 'I'),
    (N'Math', N'الرياضيات', 'I'),
    (N'Python', N'بايثون', 'I'),
    (N'Machine learning', N'تعلّم الآلة', 'I'),
    (N'Data handling', N'معالجة البيانات', 'C'),
    (N'Biology', N'الأحياء', 'I'),
    (N'Memory', N'الذاكرة', 'C'),
    (N'Empathy', N'التعاطف', 'S'),
    (N'Stress control', N'التحكم بالضغط', 'S'),
    (N'Chemistry', N'الكيمياء', 'I'),
    (N'Accuracy', N'الدقة', 'C'),
    (N'Communication', N'التواصل', 'S'),
    (N'Pharmacology', N'علم الأدوية', 'I'),
    (N'Technical drawing', N'الرسم الهندسي', 'R'),
    (N'Project planning', N'تخطيط المشاريع', 'E'),
    (N'Site safety', N'السلامة في الموقع', 'R'),
    (N'Circuit basics', N'أساسيات الدوائر', 'R'),
    (N'Physics', N'الفيزياء', 'I'),
    (N'Patient care', N'رعاية المرضى', 'S'),
    (N'Attention to detail', N'الانتباه للتفاصيل', 'C'),
    (N'Teamwork', N'العمل الجماعي', 'S'),
    (N'Leadership', N'القيادة', 'E'),
    (N'Finance basics', N'أساسيات المالية', 'C'),
    (N'Negotiation', N'التفاوض', 'E'),
    (N'Excel', N'إكسل', 'C'),
    (N'Regulations', N'الأنظمة والقوانين', 'C'),
    (N'Creativity', N'الإبداع', 'A'),
    (N'Design software', N'برامج التصميم', 'A'),
    (N'Typography', N'الخطوط', 'A'),
    (N'Visual storytelling', N'السرد البصري', 'A'),
    (N'Argument', N'الحجة', 'E'),
    (N'Reading', N'القراءة', 'C'),
    (N'Public speaking', N'الخطابة', 'E'),
    (N'Research', N'البحث', 'I'),
    (N'Listening', N'الإصغاء', 'S'),
    (N'Writing', N'الكتابة', 'A');

-- Which skills each major needs (many-to-many link table)
INSERT INTO MajorSkills (MajorID, SkillID) VALUES
    (1, 1),
    (1, 2),
    (1, 3),
    (1, 4),
    (2, 5),
    (2, 6),
    (2, 7),
    (2, 8),
    (3, 9),
    (3, 10),
    (3, 11),
    (3, 12),
    (4, 13),
    (4, 14),
    (4, 15),
    (4, 16),
    (5, 17),
    (5, 18),
    (5, 19),
    (5, 20),
    (6, 9),
    (6, 21),
    (6, 22),
    (6, 23),
    (7, 24),
    (7, 9),
    (7, 25),
    (7, 2),
    (8, 26),
    (8, 19),
    (8, 27),
    (8, 28),
    (9, 29),
    (9, 19),
    (9, 30),
    (9, 31),
    (10, 9),
    (10, 18),
    (10, 32),
    (10, 33),
    (11, 34),
    (11, 35),
    (11, 36),
    (11, 37),
    (12, 38),
    (12, 39),
    (12, 40),
    (12, 41),
    (13, 42),
    (13, 15),
    (13, 41),
    (13, 43);

-- Careers of each major (one major has many careers)
INSERT INTO Careers (MajorID, CareerName, CareerNameAr) VALUES
    (1, N'Software developer', N'مطوّر برمجيات'),
    (1, N'Web developer', N'مطوّر ويب'),
    (1, N'Data analyst', N'محلل بيانات'),
    (1, N'Systems analyst', N'محلل أنظمة'),
    (2, N'Security analyst', N'محلل أمني'),
    (2, N'Penetration tester', N'مختبِر اختراق'),
    (2, N'SOC engineer', N'مهندس مركز عمليات الأمن'),
    (2, N'Security consultant', N'مستشار أمني'),
    (3, N'ML engineer', N'مهندس تعلّم آلة'),
    (3, N'Data scientist', N'عالِم بيانات'),
    (3, N'AI researcher', N'باحث ذكاء اصطناعي'),
    (3, N'Robotics developer', N'مطوّر روبوتات'),
    (4, N'Doctor', N'طبيب'),
    (4, N'Surgeon', N'جرّاح'),
    (4, N'Medical researcher', N'باحث طبي'),
    (4, N'Specialist', N'طبيب أخصائي'),
    (5, N'Clinical pharmacist', N'صيدلي سريري'),
    (5, N'Hospital pharmacist', N'صيدلي مستشفى'),
    (5, N'Drug researcher', N'باحث أدوية'),
    (5, N'Pharma representative', N'مندوب أدوية'),
    (6, N'Site engineer', N'مهندس موقع'),
    (6, N'Structural designer', N'مصمم إنشائي'),
    (6, N'Project manager', N'مدير مشروع'),
    (6, N'Surveyor', N'مهندس مساحة'),
    (7, N'Power engineer', N'مهندس طاقة'),
    (7, N'Electronics designer', N'مصمم إلكترونيات'),
    (7, N'Telecom engineer', N'مهندس اتصالات'),
    (7, N'Automation engineer', N'مهندس أتمتة'),
    (8, N'Registered nurse', N'ممرض مسجّل'),
    (8, N'Clinic nurse', N'ممرض عيادة'),
    (8, N'Nurse educator', N'مدرّب تمريض'),
    (8, N'Health manager', N'مدير صحي'),
    (9, N'Manager', N'مدير'),
    (9, N'Business analyst', N'محلل أعمال'),
    (9, N'Entrepreneur', N'رائد أعمال'),
    (9, N'HR specialist', N'أخصائي موارد بشرية'),
    (10, N'Accountant', N'محاسب'),
    (10, N'Auditor', N'مدقق حسابات'),
    (10, N'Financial analyst', N'محلل مالي'),
    (10, N'Tax consultant', N'مستشار ضرائب'),
    (11, N'Graphic designer', N'مصمم غرافيك'),
    (11, N'UI designer', N'مصمم واجهات'),
    (11, N'Art director', N'مدير فني'),
    (11, N'Brand designer', N'مصمم هوية'),
    (12, N'Lawyer', N'محامٍ'),
    (12, N'Legal advisor', N'مستشار قانوني'),
    (12, N'Judge', N'قاضٍ'),
    (12, N'Prosecutor', N'مدّعٍ عام'),
    (13, N'Counselor', N'مرشد نفسي'),
    (13, N'School psychologist', N'أخصائي نفسي مدرسي'),
    (13, N'HR specialist', N'أخصائي موارد بشرية'),
    (13, N'Researcher', N'باحث');

-- Try a Major quiz: 4 questions per major, one for each skill
INSERT INTO QuizQuestions (MajorID, SkillID, QuestionText, RightAnswer, WrongAnswer1, WrongAnswer2, Explanation) VALUES
    (1, 1, N'What does this print?  x = 2;  x = x + 3;  print(x)', N'5', N'23', N'x', N'x becomes 2 + 3 = 5.'),
    (1, 2, N'A program crashes only when a list is empty. Best first step?', N'Reproduce the crash with an empty list', N'Rewrite everything', N'Ignore it', N'Reproducing the exact case shows the cause.'),
    (1, 3, N'Find a name in a sorted list of 1,000,000 names. Fastest method?', N'Binary search (halve the list each time)', N'Check names one by one', N'Pick names randomly', N'Halving needs only about 20 steps.'),
    (1, 4, N'Which feature keeps every student record unique in a table?', N'A primary key', N'A font', N'A color', N'A primary key identifies each row.'),
    (2, 5, N'Which device forwards data between different networks?', N'Router', N'Monitor', N'Keyboard', N'Routers connect networks together.'),
    (2, 6, N'An email says: click this link and enter your password. What is it?', N'Phishing', N'A reward', N'A backup', N'Real services never ask for passwords by link.'),
    (2, 7, N'Which Linux command lists the files in a folder?', N'ls', N'cd', N'rm', N'ls means list.'),
    (2, 8, N'Which risk should be fixed first?', N'High impact and likely to happen', N'Low impact and unlikely', N'One nobody can notice', N'Prioritize by impact times likelihood.'),
    (3, 9, N'The average of 2, 4 and 9 is?', N'5', N'6', N'15', N'(2 + 4 + 9) / 3 = 5.'),
    (3, 10, N'In Python, which expression gives the length of a list called nums?', N'len(nums)', N'nums.size', N'count(nums)', N'len() returns the number of items.'),
    (3, 11, N'What are the examples a model learns from called?', N'Training data', N'Hardware', N'Wallpaper', N'Models learn patterns from training data.'),
    (3, 12, N'A data column has many missing values. A sensible first step?', N'Find out why they are missing', N'Delete the whole dataset', N'Fill them with random words', N'Understand the problem before cleaning.'),
    (4, 13, N'Which organ pumps blood around the body?', N'The heart', N'The liver', N'The kidney', N'The heart is the pump of the circulatory system.'),
    (4, 14, N'What is the best way to remember a long list?', N'Group it and repeat it over several days', N'Read it once, fast', N'Skip it', N'Spaced repetition builds long-term memory.'),
    (4, 15, N'A patient is scared of a test. What do you say first?', N'I understand it feels scary. Let me explain it.', N'Don''t worry, it is nothing.', N'We are busy.', N'Acknowledge feelings before explaining.'),
    (4, 16, N'Two emergencies arrive at the same time. What helps most?', N'Stay calm and decide by urgency', N'Panic', N'Wait and see', N'Triage means treating the most urgent first.'),
    (5, 17, N'A solution has pH 2. It is?', N'Acidic', N'Neutral', N'Basic', N'Below pH 7 is acidic.'),
    (5, 18, N'You need 250 mg and tablets are 500 mg each. How many tablets?', N'Half a tablet', N'Two tablets', N'One tablet', N'250 is half of 500.'),
    (5, 19, N'A patient asks when to take a pill. Best answer?', N'Give the exact time, with or without food, and what to avoid', N'It depends', N'Read the leaflet', N'Clear, specific advice prevents mistakes.'),
    (5, 20, N'Why do pharmacists ask which other medicines you take?', N'Medicines can interact', N'For fun', N'For billing only', N'Interactions can be dangerous.'),
    (6, 9, N'A road is 3 km long and 8 m wide. Area in square meters?', N'24,000', N'2,400', N'240,000', N'3,000 m x 8 m = 24,000.'),
    (6, 21, N'On a 1:100 plan a wall measures 5 cm. Real length?', N'5 m', N'50 m', N'0.5 m', N'5 cm x 100 = 500 cm = 5 m.'),
    (6, 22, N'Concrete must dry before the next floor is built. This is a?', N'Dependency between tasks', N'A bonus', N'A mistake', N'Some tasks cannot start before others finish.'),
    (6, 23, N'What must you wear before entering a building site?', N'Helmet and safety boots', N'Sandals', N'Nothing special', N'Head and foot protection are basic site rules.'),
    (7, 24, N'In a series circuit, one lamp breaks. The others?', N'Go off', N'Get brighter', N'Stay on', N'There is only one path for the current.'),
    (7, 9, N'Solve: 3x + 6 = 18', N'x = 4', N'x = 8', N'x = 6', N'3x = 12, so x = 4.'),
    (7, 25, N'Power = voltage x current. 10 V and 2 A give?', N'20 W', N'5 W', N'12 W', N'10 x 2 = 20 W.'),
    (7, 2, N'A device will not turn on. What do you check first?', N'Power supply and connections', N'Rewrite the code', N'Buy a new one', N'Start with the simplest causes.'),
    (8, 26, N'A patient stays in bed for days. What helps prevent pressure sores?', N'Change their position regularly', N'Nothing', N'Keep them in one position', N'Moving relieves pressure on the skin.'),
    (8, 19, N'How do you confirm a patient understood your instructions?', N'Ask them to explain it back', N'Say it louder', N'Assume they did', N'Asking them to repeat checks understanding.'),
    (8, 27, N'Before giving a medicine you check?', N'Right patient, drug, dose and time', N'Only the drug name', N'Only the time', N'Checking all four prevents errors.'),
    (8, 28, N'You notice a colleague made a small error. Best action?', N'Tell them politely and report if needed', N'Hide it', N'Blame them', N'Safety comes first, and respect keeps the team strong.'),
    (9, 29, N'A teammate is struggling. A good leader?', N'Listens and offers help', N'Ignores it', N'Takes the credit', N'Good leaders support their team.'),
    (9, 19, N'Best way to start an email to a client?', N'A clear subject and a short purpose', N'A long story', N'No subject at all', N'Clients want clarity quickly.'),
    (9, 30, N'Revenue is 1,000 and costs are 700. Profit?', N'300', N'1,700', N'700', N'1,000 - 700 = 300.'),
    (9, 31, N'A supplier asks for a higher price. A good move?', N'Ask what you get for it, then counter-offer', N'Accept at once', N'Walk out angry', N'Negotiation is about value for both sides.'),
    (10, 9, N'What is 15% of 200?', N'30', N'15', N'20', N'0.15 x 200 = 30.'),
    (10, 18, N'A report says 1,250 but the receipts add up to 1,205. You?', N'Recheck the numbers', N'Leave it', N'Round it up', N'Accounting needs exact figures.'),
    (10, 32, N'Which Excel function adds the numbers in a range?', N'SUM', N'COUNT', N'TEXT', N'SUM adds values together.'),
    (10, 33, N'Why do companies keep financial records?', N'Laws and audits require them', N'Decoration', N'No reason', N'Records prove what happened and satisfy the law.'),
    (11, 34, N'A client wants a poster for a book fair. First step?', N'Sketch several ideas', N'Choose a font', N'Print it', N'Ideas come before polishing.'),
    (11, 35, N'Which file type keeps a logo sharp at any size?', N'Vector (SVG)', N'Low-resolution JPG', N'A screenshot', N'Vectors scale without losing quality.'),
    (11, 36, N'What makes body text easy to read?', N'A simple font, enough size and spacing', N'Many different fonts', N'Tiny text', N'Clear type and space help the eye.'),
    (11, 37, N'Three images tell a story. Best order?', N'Beginning, middle, end', N'Random order', N'The same image three times', N'A story needs a clear flow.'),
    (12, 38, N'Which is the strongest argument?', N'A claim supported by evidence', N'A loud opinion', N'An insult', N'Evidence makes an argument convincing.'),
    (12, 39, N'A contract says ''may'' instead of ''must''. What changes?', N'May is optional, must is required', N'Nothing', N'May is stronger', N'Exact words decide legal duties.'),
    (12, 40, N'To keep a court audience with you, you should?', N'Speak clearly and organize your points', N'Read very fast', N'Mumble', N'Structure and clarity persuade.'),
    (12, 41, N'Best source for a legal question?', N'The official text of the law', N'A rumor', N'A meme', N'Always go to the primary source.'),
    (13, 42, N'A friend shares a problem. Best response?', N'Listen and say back what you heard', N'Interrupt with advice', N'Change the topic', N'Reflecting shows you understood.'),
    (13, 15, N'Someone says: I failed my exam. Most empathic reply?', N'That sounds hard. How are you feeling?', N'Just study more.', N'Whatever.', N'Empathy starts by recognizing feelings.'),
    (13, 41, N'To test whether sleep improves memory you need?', N'A comparison group', N'Only opinions', N'One single person', N'Comparing groups shows cause and effect.'),
    (13, 43, N'A good case note is?', N'Clear, factual and objective', N'Full of guesses', N'Long and vague', N'Notes should record facts, not assumptions.');

-- Try a Major answers: 1 = correct, 0 = wrong (Lina did Computer Science, Omar did Medicine)
INSERT INTO QuizResults (UserID, MajorID, SkillID, IsCorrect, TakenAt) VALUES
    (1, 1, 1, 1, '2026-10-03T11:00:00'),
    (1, 1, 2, 0, '2026-10-03T11:00:00'),
    (1, 1, 3, 1, '2026-10-03T11:00:00'),
    (1, 1, 4, 0, '2026-10-03T11:00:00'),
    (2, 4, 13, 1, '2026-09-22T11:00:00'),
    (2, 4, 14, 1, '2026-09-22T11:00:00'),
    (2, 4, 15, 1, '2026-09-22T11:00:00'),
    (2, 4, 16, 0, '2026-09-22T11:00:00');

-- Messages from the Contact page
INSERT INTO Messages (FullName, Email, Subject, MessageText, Status, SentAt) VALUES
    (N'Rawan Said', N'rawan@mail.com', N'Report a problem', N'The campus tour does not load the Google map on my phone. Is there a fix?', N'new', '2026-10-14T09:00:00'),
    (N'Basel Nimer', N'basel@mail.com', N'University data correction', N'The minimum average for Computer Science at my university is different. Where can I send the correct number?', N'new', '2026-10-13T09:00:00'),
    (N'Maya Zureik', N'maya@mail.com', N'Suggest a feature', N'Please add scholarships information for each university. It would help many students.', N'read', '2026-10-11T09:00:00'),
    (N'Fadi Awad', N'fadi@mail.com', N'General question', N'Is Masari free for all Tawjihi students?', N'replied', '2026-10-09T09:00:00'),
    (N'Lujain Tamimi', N'lujain@mail.com', N'Report a problem', N'I could not log in with my email. The password rules message was unclear.', N'read', '2026-10-05T09:00:00'),
    (N'Zaid Bataineh', N'zaid@mail.com', N'Suggest a feature', N'Can you add a dark mode?', N'replied', '2026-09-29T09:00:00');

-- Subscription history: one row for every paid plan
INSERT INTO Subscriptions (UserID, PlanID, StartDate, PricePaid) VALUES
    (2, 2, '2026-09-21T10:30:00', 4.99),
    (3, 3, '2026-09-14T10:30:00', 9.99),
    (4, 2, '2026-08-30T10:30:00', 4.99),
    (7, 2, '2026-07-25T10:30:00', 4.99),
    (9, 3, '2026-06-29T10:30:00', 9.99),
    (11, 2, '2026-05-20T10:30:00', 4.99);

-- Site settings (the admin Settings page)
INSERT INTO Settings (SettingKey, SettingValue) VALUES
    (N'FreeMajorsLimit', N'3'),
    (N'SiteName', N'Masari'),
    (N'MaintenanceMode', N'0');

-- Activity log (the admin Dashboard feed)
INSERT INTO ActivityLog (UserID, ActionText, CreatedAt) VALUES
    (9, N'Hiba Alami upgraded to Campus Pass', '2026-10-14T08:00:00'),
    (NULL, N'New message from Rawan Said', '2026-10-14T09:00:00'),
    (1, N'Lina Haddad created an account', '2026-10-02T10:00:00'),
    (2, N'Omar Khalil upgraded to Premium', '2026-09-21T10:30:00');
GO

/* =====================================================================
   PART 4 : SQL DAY 01
   ===================================================================== */

/* ---- 4.1 What is a database? ----
   A database is an organized place to store data. A relational database (SQL Server, MySQL,
   PostgreSQL) stores data in TABLES that are connected by keys. A non-relational database
   (MongoDB, Firebase) stores flexible documents. Masari is relational because a student, a plan,
   a major and a university are clearly connected.
   Table = a list of one kind of thing (Users). Row = one item (one student). Column = one fact (Email). */

/* ---- 4.2 Structure statements (DDL): CREATE / ALTER / DROP / TRUNCATE ----
   We practice on a small table called PracticeNotes, so the real tables stay safe. */
CREATE TABLE PracticeNotes (
    NoteID   INT IDENTITY(1,1) PRIMARY KEY,
    NoteText NVARCHAR(100) NOT NULL
);

INSERT INTO PracticeNotes (NoteText) VALUES (N'first note'), (N'second note');

-- ALTER TABLE changes a table that already exists
ALTER TABLE PracticeNotes ADD CreatedBy NVARCHAR(50) NULL;           -- add a column
ALTER TABLE PracticeNotes ALTER COLUMN CreatedBy NVARCHAR(80) NULL;  -- change its type or size
ALTER TABLE PracticeNotes DROP COLUMN CreatedBy;                     -- remove the column

-- TRUNCATE TABLE deletes ALL the rows quickly but keeps the table
TRUNCATE TABLE PracticeNotes;
SELECT * FROM PracticeNotes;                                          -- empty now

-- DROP TABLE deletes the table itself
DROP TABLE PracticeNotes;
-- (DROP DATABASE MasariDB; would delete the whole database, see PART 1)
GO

/* ---- 4.3 Data statements (DML): SELECT / INSERT / UPDATE / DELETE ---- */

-- INSERT: add a new student
INSERT INTO Users (FullName, Email, PasswordHash, CityID, AvatarNo, CareerGoal, PlanID, ChosenMajorID, Role, Status, CreatedAt)
VALUES (N'Test Student', N'test.student@mail.com', N'demo-hash', 1, 0, NULL, 1, NULL, N'student', N'active', GETDATE());

-- SELECT: read data.  * means "all columns"
SELECT * FROM Users WHERE Email = N'test.student@mail.com';

-- UPDATE: change data.  ALWAYS use WHERE, or every row will change!
UPDATE Users
SET CareerGoal = N'Software engineer'
WHERE Email = N'test.student@mail.com';

-- DELETE: remove rows.  ALWAYS use WHERE, or every row will be deleted!
DELETE FROM Users WHERE Email = N'test.student@mail.com';

-- More SELECT examples
SELECT FullName, Email, Status                       -- only the columns we need
FROM Users
WHERE Status = N'active' AND PlanID > 1              -- AND / OR to combine conditions
ORDER BY FullName;                                   -- sort A to Z (add DESC for Z to A)

SELECT MajorName, MinAverage
FROM Majors
WHERE MajorName LIKE N'%Engineering%';               -- LIKE searches inside the text

SELECT TOP 5 MajorName, ViewsCount                   -- TOP 5 = only the first 5 rows
FROM Majors
ORDER BY ViewsCount DESC;                            -- the 5 most viewed majors

/* ---- 4.4 Aggregation functions: COUNT, SUM, AVG, MIN, MAX ----
   They turn many rows into one number. */
SELECT COUNT(*) AS TotalUsers FROM Users;                                   -- how many rows
SELECT AVG(Average) AS AverageScore,                                       -- the mean
       MIN(Average) AS LowestScore,                                        -- the smallest
       MAX(Average) AS HighestScore                                        -- the biggest
FROM TawjihiResults;
SELECT SUM(PricePaid) AS TotalPaid, COUNT(*) AS PaidSubscriptions           -- the total
FROM Subscriptions;
GO

/* =====================================================================
   PART 5 : SQL DAY 02
   ===================================================================== */

/* ---- 5.1 Relations and the schema ----
   SCHEMA = the plan of the database: its tables, columns, keys and how they connect.
   (All Masari tables live in the default schema called dbo.)

   ONE-TO-ONE    Users  1 --- 1  TawjihiResults      (a student has one Tawjihi result)
   ONE-TO-MANY   Cities 1 --- *  Universities        (a city has many universities)
                 Plans  1 --- *  Users                (a plan has many users)
                 Majors 1 --- *  Careers, QuizQuestions
                 Universities 1 --- * CampusSpots
                 Users  1 --- *  QuizResults, Subscriptions, InterestScores
   MANY-TO-MANY  Universities * --- * Majors   through the link table UniversityMajors
                 Majors * --- * Skills         through the link table MajorSkills

   FOREIGN KEY = a column that stores the ID of a row in another table (Universities.CityID -> Cities.CityID). */

/* ---- 5.2 Joins: take columns from two or more tables ----
   INNER JOIN  = only rows that match on both sides
   LEFT JOIN   = all rows from the LEFT table + matches from the right (NULL when no match)
   RIGHT JOIN  = all rows from the RIGHT table + matches from the left
   FULL JOIN   = all rows from both sides */

-- INNER JOIN through a ONE-TO-ONE relation: students with their Tawjihi result
SELECT u.FullName, t.Average, s.StreamName
FROM Users u
INNER JOIN TawjihiResults t ON t.UserID = u.UserID
INNER JOIN Streams s        ON s.StreamID = t.StreamID;

-- INNER JOIN through a ONE-TO-MANY relation: every university with its city
SELECT un.UniversityName, c.CityName
FROM Universities un
INNER JOIN Cities c ON c.CityID = un.CityID;

-- INNER JOIN through a MANY-TO-MANY relation: universities that offer Computer Science
-- (we go through the link table UniversityMajors)
SELECT un.UniversityName, c.CityName
FROM Universities un
INNER JOIN UniversityMajors um ON um.UniversityID = un.UniversityID
INNER JOIN Majors m            ON m.MajorID = um.MajorID
INNER JOIN Cities c            ON c.CityID = un.CityID
WHERE m.MajorName = N'Computer Science';

-- LEFT JOIN: cities that have NO university in our data
SELECT c.CityName
FROM Cities c
LEFT JOIN Universities un ON un.CityID = c.CityID
WHERE un.UniversityID IS NULL;

-- RIGHT JOIN: the same question written from the other side
SELECT c.CityName
FROM Universities un
RIGHT JOIN Cities c ON c.CityID = un.CityID
WHERE un.UniversityID IS NULL;

-- FULL JOIN: all students AND all messages, even when they do not match by email
SELECT u.FullName AS StudentName, m.FullName AS MessageSender, m.Subject
FROM Users u
FULL OUTER JOIN Messages m ON m.Email = u.Email;

/* ---- 5.3 WHERE, GROUP BY, HAVING ----
   WHERE    filters ROWS before grouping.
   GROUP BY makes one row for each group.
   HAVING   filters the GROUPS after grouping (it works with COUNT, SUM ...). */

-- WHERE: majors that need an average of 80 or more
SELECT MajorName, MinAverage
FROM Majors
WHERE MinAverage >= 80
ORDER BY MinAverage DESC;

-- GROUP BY: how many universities in each city
SELECT c.CityName, COUNT(*) AS UniversitiesCount
FROM Cities c
INNER JOIN Universities un ON un.CityID = c.CityID
GROUP BY c.CityName;

-- HAVING: only the cities that have 2 universities or more
SELECT c.CityName, COUNT(*) AS UniversitiesCount
FROM Cities c
INNER JOIN Universities un ON un.CityID = c.CityID
GROUP BY c.CityName
HAVING COUNT(*) >= 2;

-- GROUP BY with a LEFT JOIN: how many users on each plan (a plan with no users shows 0)
SELECT p.PlanName, COUNT(u.UserID) AS UsersCount
FROM Plans p
LEFT JOIN Users u ON u.PlanID = p.PlanID
GROUP BY p.PlanName;

-- WHERE + GROUP BY + HAVING together: cities with at least 2 PUBLIC universities
SELECT c.CityName, COUNT(*) AS PublicUniversities
FROM Cities c
INNER JOIN Universities un ON un.CityID = c.CityID
WHERE un.UniType = N'Public'
GROUP BY c.CityName
HAVING COUNT(*) >= 2;
GO

/* ---- 5.4 Indexes ----
   An index is like the index of a book: it makes searching faster.
   CLUSTERED     = the table itself is stored in this order. A table has only ONE.
                   SQL Server creates it automatically for every PRIMARY KEY.
   NON-CLUSTERED = a separate list that points to the rows. A table can have many. */
CREATE NONCLUSTERED INDEX IX_Universities_CityID    ON Universities (CityID);
CREATE NONCLUSTERED INDEX IX_UniversityMajors_Major ON UniversityMajors (MajorID);
CREATE NONCLUSTERED INDEX IX_Users_PlanID           ON Users (PlanID);
CREATE NONCLUSTERED INDEX IX_QuizResults_UserID     ON QuizResults (UserID);
CREATE NONCLUSTERED INDEX IX_ActivityLog_CreatedAt  ON ActivityLog (CreatedAt);

-- See all the indexes of a table (the PK index is the clustered one)
EXEC sp_helpindex 'Users';

-- A clustered index on a table that has no primary key (practice table)
CREATE TABLE PracticeLog (LogText NVARCHAR(100) NOT NULL, CreatedAt DATETIME NOT NULL);
CREATE CLUSTERED INDEX IX_PracticeLog_CreatedAt ON PracticeLog (CreatedAt);
DROP TABLE PracticeLog;
GO

/* ---- 5.5 Views ----
   A view is a saved SELECT. You use it like a table, and it always shows fresh data. */

-- Everything about a student in one place (Profile page, Admin > Users)
CREATE VIEW vw_UserSummary AS
SELECT u.UserID, u.FullName, u.Email, c.CityName, p.PlanName,
       t.Average, s.StreamName, mj.MajorName AS ChosenMajor
FROM Users u
LEFT JOIN Cities c          ON c.CityID = u.CityID
INNER JOIN Plans p          ON p.PlanID = u.PlanID
LEFT JOIN TawjihiResults t  ON t.UserID = u.UserID
LEFT JOIN Streams s         ON s.StreamID = t.StreamID
LEFT JOIN Majors mj         ON mj.MajorID = u.ChosenMajorID;
GO

-- Which university offers which major (University Explorer)
CREATE VIEW vw_UniversityMajorList AS
SELECT un.UniversityID, un.UniversityName, c.CityName, un.UniType, m.MajorID, m.MajorName
FROM Universities un
INNER JOIN Cities c            ON c.CityID = un.CityID
INNER JOIN UniversityMajors um ON um.UniversityID = un.UniversityID
INNER JOIN Majors m            ON m.MajorID = um.MajorID;
GO

-- A major with the number of universities that offer it (Major details, Admin > Majors)
CREATE VIEW vw_MajorDetails AS
SELECT m.MajorID, m.MajorName, m.MinAverage, m.StudyYears, m.InterestCode,
       COUNT(um.UniversityID) AS UniversitiesCount
FROM Majors m
LEFT JOIN UniversityMajors um ON um.MajorID = m.MajorID
GROUP BY m.MajorID, m.MajorName, m.MinAverage, m.StudyYears, m.InterestCode;
GO

SELECT * FROM vw_UserSummary;
SELECT * FROM vw_MajorDetails;
GO

/* ---- 5.6 Functions ----
   A function takes values and RETURNS one value. We use them for the two main rules of Masari. */

-- Rule 1: can this student enter this major? (returns 1 = yes, 0 = no)
CREATE FUNCTION dbo.fn_IsEligible (@UserID INT, @MajorID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @Average DECIMAL(4,1), @Stream NVARCHAR(30), @MinAverage DECIMAL(4,1), @ScientificOnly BIT;

    SELECT @Average = t.Average, @Stream = s.StreamName
    FROM TawjihiResults t
    INNER JOIN Streams s ON s.StreamID = t.StreamID
    WHERE t.UserID = @UserID;

    SELECT @MinAverage = MinAverage, @ScientificOnly = ScientificOnly
    FROM Majors
    WHERE MajorID = @MajorID;

    IF @Average IS NULL RETURN 0;                                  -- no Tawjihi result yet
    IF @Average < @MinAverage RETURN 0;                            -- average is too low
    IF @ScientificOnly = 1 AND @Stream <> N'Scientific' RETURN 0;  -- wrong stream
    RETURN 1;
END
GO

-- Rule 2: how well does this major match this student? (0 to 100)
-- match = 65% interest fit + 35% how far the average is above the minimum (same as the website)
CREATE FUNCTION dbo.fn_MatchPercent (@UserID INT, @MajorID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Code CHAR(3), @MinAverage DECIMAL(4,1), @Average DECIMAL(4,1);
    DECLARE @S1 INT, @S2 INT, @S3 INT;

    SELECT @Code = InterestCode, @MinAverage = MinAverage FROM Majors WHERE MajorID = @MajorID;
    SELECT @Average = Average FROM TawjihiResults WHERE UserID = @UserID;

    -- the student's score for each of the 3 letters of the major (first letter counts 3, second 2, third 1)
    SELECT @S1 = Score FROM InterestScores WHERE UserID = @UserID AND Letter = SUBSTRING(@Code, 1, 1);
    SELECT @S2 = Score FROM InterestScores WHERE UserID = @UserID AND Letter = SUBSTRING(@Code, 2, 1);
    SELECT @S3 = Score FROM InterestScores WHERE UserID = @UserID AND Letter = SUBSTRING(@Code, 3, 1);

    -- if the student did not take the interest test, use a middle score (6)
    IF @S1 IS NULL SET @S1 = 6;
    IF @S2 IS NULL SET @S2 = 6;
    IF @S3 IS NULL SET @S3 = 6;

    DECLARE @Interest DECIMAL(6,4), @Gap DECIMAL(6,4), @Fit DECIMAL(6,4);
    SET @Interest = (3 * @S1 + 2 * @S2 + 1 * @S3) / 6.0 / 10.0;    -- 0 to 1
    SET @Gap = (@Average - @MinAverage) / 15.0;                     -- keep it between 0 and 1
    IF @Gap < 0 SET @Gap = 0;
    IF @Gap > 1 SET @Gap = 1;
    SET @Fit = 0.6 + 0.4 * @Gap;

    RETURN CAST(ROUND(100 * (0.65 * @Interest + 0.35 * @Fit), 0) AS INT);
END
GO

-- A view that uses both functions: every major a student can enter, with its match percent
CREATE VIEW vw_UserMajorMatches AS
SELECT u.UserID, u.FullName, m.MajorID, m.MajorName,
       dbo.fn_MatchPercent(u.UserID, m.MajorID) AS MatchPercent
FROM Users u
INNER JOIN Majors m ON m.IsVisible = 1
WHERE dbo.fn_IsEligible(u.UserID, m.MajorID) = 1;
GO

-- Try them
SELECT dbo.fn_IsEligible(1, 1) AS CanLinaEnterComputerScience;
SELECT dbo.fn_MatchPercent(1, 1) AS LinaMatchWithComputerScience;
SELECT * FROM vw_UserMajorMatches WHERE UserID = 1 ORDER BY MatchPercent DESC;
GO

/* ---- 5.7 Stored procedures ----
   A stored procedure is a saved group of SQL statements with parameters (@Name).
   You run it with EXEC. The website backend will call these procedures. */

-- Register page: create a new student (plan 1 = Free)
CREATE PROCEDURE usp_RegisterUser
    @FullName NVARCHAR(100), @Email NVARCHAR(150), @PasswordHash NVARCHAR(200), @CityID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
    BEGIN
        SELECT N'This email already exists' AS Message;
        RETURN;
    END

    INSERT INTO Users (FullName, Email, PasswordHash, CityID, AvatarNo, CareerGoal, PlanID, ChosenMajorID, Role, Status, CreatedAt)
    VALUES (@FullName, @Email, @PasswordHash, @CityID, 0, NULL, 1, NULL, N'student', N'active', GETDATE());

    SELECT UserID, FullName, Email FROM Users WHERE Email = @Email;
END
GO

-- Tawjihi Score page: save the average and the stream (insert the first time, update after that)
CREATE PROCEDURE usp_SaveTawjihiResult
    @UserID INT, @Average DECIMAL(4,1), @StreamID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM TawjihiResults WHERE UserID = @UserID)
        UPDATE TawjihiResults SET Average = @Average, StreamID = @StreamID, SavedAt = GETDATE() WHERE UserID = @UserID;
    ELSE
        INSERT INTO TawjihiResults (UserID, Average, StreamID, SavedAt) VALUES (@UserID, @Average, @StreamID, GETDATE());
END
GO

-- Interest Test page: save ONE letter score (the backend calls it 6 times)
CREATE PROCEDURE usp_SaveInterestScore
    @UserID INT, @Letter CHAR(1), @Score INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM InterestScores WHERE UserID = @UserID AND Letter = @Letter)
        UPDATE InterestScores SET Score = @Score WHERE UserID = @UserID AND Letter = @Letter;
    ELSE
        INSERT INTO InterestScores (UserID, Letter, Score) VALUES (@UserID, @Letter, @Score);
END
GO

-- Top Majors page: best matches. Free plan sees only the number set in Settings (3), others see 10.
CREATE PROCEDURE usp_GetTopMajors
    @UserID INT
AS
BEGIN
    DECLARE @PlanID INT, @Limit INT;
    SELECT @PlanID = PlanID FROM Users WHERE UserID = @UserID;

    IF @PlanID = 1
        SELECT @Limit = CAST(SettingValue AS INT) FROM Settings WHERE SettingKey = N'FreeMajorsLimit';
    ELSE
        SET @Limit = 10;

    SELECT TOP (@Limit) MajorID, MajorName, MatchPercent
    FROM vw_UserMajorMatches
    WHERE UserID = @UserID
    ORDER BY MatchPercent DESC;
END
GO

-- Skills Gap page: the SYSTEM calculates the gap (the student does not rate himself)
--   level = 70% quiz answer (correct = 100, wrong = 20) + 30% interest score (x10)
--   gap   = 100 - level.   NULL means "no quiz answer yet".
CREATE PROCEDURE usp_SkillsGap
    @UserID INT, @MajorID INT
AS
BEGIN
    SELECT sk.SkillName,
           sk.RiasecType,
           qr.IsCorrect,
           i.Score AS InterestScore,
           100 - (0.7 * (20 + 80 * CAST(qr.IsCorrect AS INT)) + 0.3 * (i.Score * 10)) AS GapPercent
    FROM MajorSkills ms
    INNER JOIN Skills sk          ON sk.SkillID = ms.SkillID
    LEFT JOIN QuizResults qr      ON qr.SkillID = sk.SkillID AND qr.UserID = @UserID AND qr.MajorID = @MajorID
    LEFT JOIN InterestScores i    ON i.Letter = sk.RiasecType AND i.UserID = @UserID
    WHERE ms.MajorID = @MajorID
    ORDER BY GapPercent DESC;
END
GO

-- Upgrade page: change the plan (the trigger in 5.9 writes the Subscriptions row)
CREATE PROCEDURE usp_UpgradePlan
    @UserID INT, @PlanID INT
AS
BEGIN
    UPDATE Users SET PlanID = @PlanID WHERE UserID = @UserID;
END
GO

-- Contact page: save a message
CREATE PROCEDURE usp_SendMessage
    @FullName NVARCHAR(100), @Email NVARCHAR(150), @Subject NVARCHAR(80), @MessageText NVARCHAR(1000)
AS
BEGIN
    INSERT INTO Messages (FullName, Email, Subject, MessageText, Status, SentAt)
    VALUES (@FullName, @Email, @Subject, @MessageText, N'new', GETDATE());
END
GO

-- Admin Dashboard: the big numbers (each number is a small subquery)
CREATE PROCEDURE usp_AdminDashboard
AS
BEGIN
    SELECT
        (SELECT COUNT(*) FROM Users WHERE Role = N'student')   AS Students,
        (SELECT COUNT(*) FROM Users WHERE PlanID > 1)          AS PaidUsers,
        (SELECT ISNULL(SUM(p.PriceJOD), 0)
         FROM Users u INNER JOIN Plans p ON p.PlanID = u.PlanID) AS MonthlyRevenueJOD,
        (SELECT COUNT(*) FROM Messages WHERE Status = N'new')  AS NewMessages;
END
GO

-- Try the procedures
EXEC usp_GetTopMajors @UserID = 1;                -- Lina is on the Free plan: only 3 rows
EXEC usp_GetTopMajors @UserID = 2;                -- Omar is on Premium: up to 10 rows
EXEC usp_SkillsGap @UserID = 1, @MajorID = 1;     -- Lina's skills gap for Computer Science
EXEC usp_AdminDashboard;
GO

/* ---- 5.8 Subqueries ----
   A subquery is a SELECT inside another SELECT (written inside brackets). */

-- Students whose average is higher than the average of everybody
SELECT FullName
FROM Users
WHERE UserID IN (SELECT UserID FROM TawjihiResults
                 WHERE Average > (SELECT AVG(Average) FROM TawjihiResults));

-- Majors offered by the University of Jordan (UniversityID = 1)
SELECT MajorName
FROM Majors
WHERE MajorID IN (SELECT MajorID FROM UniversityMajors WHERE UniversityID = 1);

-- Students who did NOT take the interest test yet
SELECT FullName
FROM Users
WHERE Role = N'student'
  AND UserID NOT IN (SELECT UserID FROM InterestScores);

-- A subquery inside the SELECT list: each major with its number of universities
SELECT m.MajorName,
       (SELECT COUNT(*) FROM UniversityMajors um WHERE um.MajorID = m.MajorID) AS UniversitiesCount
FROM Majors m;
GO

/* ---- 5.9 Triggers ----
   A trigger runs by itself when a table changes (INSERT, UPDATE or DELETE).
   Inside it, the virtual table "inserted" has the NEW rows and "deleted" has the OLD rows. */

-- When a student creates an account, write a line in the activity log
CREATE TRIGGER trg_Users_Created
ON Users
AFTER INSERT
AS
BEGIN
    INSERT INTO ActivityLog (UserID, ActionText, CreatedAt)
    SELECT UserID, FullName + N' created an account', GETDATE()
    FROM inserted;
END
GO

-- When the plan of a student changes, save it in Subscriptions and in the activity log
CREATE TRIGGER trg_Users_PlanChanged
ON Users
AFTER UPDATE
AS
BEGIN
    IF UPDATE(PlanID)
    BEGIN
        INSERT INTO Subscriptions (UserID, PlanID, StartDate, PricePaid)
        SELECT i.UserID, i.PlanID, GETDATE(), p.PriceJOD
        FROM inserted i
        INNER JOIN deleted d ON d.UserID = i.UserID
        INNER JOIN Plans p   ON p.PlanID = i.PlanID
        WHERE i.PlanID <> d.PlanID;

        INSERT INTO ActivityLog (UserID, ActionText, CreatedAt)
        SELECT i.UserID, i.FullName + N' changed plan to ' + p.PlanName, GETDATE()
        FROM inserted i
        INNER JOIN deleted d ON d.UserID = i.UserID
        INNER JOIN Plans p   ON p.PlanID = i.PlanID
        WHERE i.PlanID <> d.PlanID;
    END
END
GO

-- Try the triggers (these change the sample data a little)
EXEC usp_RegisterUser @FullName = N'Sama Nabil', @Email = N'sama.n@mail.com', @PasswordHash = N'demo-hash', @CityID = 1;
EXEC usp_UpgradePlan @UserID = 12, @PlanID = 2;
SELECT * FROM ActivityLog ORDER BY CreatedAt DESC;
SELECT * FROM Subscriptions WHERE UserID = 12;
GO

/* ---- 5.10 Normalization and denormalization ----
   Normalization = organize tables so the same fact is stored ONCE.

   1NF  one value per cell, no repeating columns.
        Example: the interest test is 6 ROWS in InterestScores, not 6 columns (R, I, A, S, E, C).
   2NF  every column depends on the WHOLE key.
        Example: the name of a skill is NOT stored in MajorSkills. That table has only the two IDs.
   3NF  columns depend only on the key, not on other columns.
        Example: a user stores CityID, not the city name and not the city name in Arabic.
        Cities, Streams and Plans are separate lookup tables for this reason.
   Result: to change the name of a city you change ONE row, and every user sees the new name.

   Denormalization = keep a small copy of data on purpose to make things faster or simpler.
   * Users.PlanID is the CURRENT plan. The full history is in Subscriptions (the same fact twice,
     kept in sync by the trigger trg_Users_PlanChanged). It makes the website check a plan fast.
   * Majors.ViewsCount is a stored counter, so the dashboard does not count every visit again.
   Rule of thumb: normalize first, denormalize only when you have a clear reason. */
