// import ballerinax/mysql;
import ballerina/io;
import ballerina/time;

public function main() returns error? {
    RainierClient rainier = new ();

    // Inserts
    Building building = check rainier->/buildings.insert(check randomBuilding());

    Department engeeringDept = check rainier->/departments.insert({deptName: "Engineering", buildings: [{buildingCode: building.buildingCode}]});
    io:println("Inserted department: ", engeeringDept);

    // Inserting an employee with a reference to the deptNo 
    // Inserting an employee with a non-existing department is not yet supported.
    // Similarly, inserting a department with references to non-existing employees is not yet supported.
    _ = check rainier->/employees.insert({
        firstName: "Jack",
        lastName: "Ryan",
        birthDate: {year: 1976, month: 4, day: 23},
        gender: M,
        hireDate: {year: 2019, month: 12, day: 23},
        department: {deptNo: engeeringDept.deptNo},
        workspace: {workspaceId: "WS-1234"}
    });

    // Insert many 
    string[] departmentNames = check getDepartmentNames();
    DepartmentInsert[] deptInserts = from string deptName in departmentNames
        select {deptName: deptName, buildings: [{buildingCode: building.buildingCode}]};

    int count = check rainier->/departments.insertMany(deptInserts);
    io:println(string `Inserted ${count} departments`);

    // Projection
    stream<Department, error?> deptStream = rainier->/departments.selectMany();
    string[] deptNos = check from var dept in deptStream
        select dept.deptNo;

    // Inserting 100 employees
    EmployeeInsert[] empInserts = from var _ in 1 ... 100
        select check randomEmployee(deptNos);
    count = check rainier->/employees.insertMany(empInserts);
    io:println(string `Inserted ${count} employees`);

    // Select
    deptStream = rainier->/departments.selectMany();
    Department[] departments = check from var dept in deptStream
        select dept;
    io:println("Departments: ", departments);

    stream<Employee, error?> empStream = rainier->/employees.selectMany();
    Employee[] employees = check from var emp in empStream
        where emp.gender == M && emp.birthDate.year > 1995
        select emp;
    io:println("Employees: ", employees);

    // var employees1 = check from var emp in rainier->/employees.'select()
    //     where emp.gender == M && emp.birthDate.year > 1995
    //     join var dept in rainier->/departments.'select() on emp.deptNo equals dept.deptNo
    //     select {department:dept, ...emp};
    // io:println("Employees: ", employees1);

    if employees.length() > 0 {
        // Update
        Employee emp = employees[0];
        Employee updatedEmp = check rainier->/employees.update(uniqueKey = {empNo: emp.empNo}, data = {lastName: "Doe"});
        io:println("Updated employee: ", updatedEmp);

        // Delete
        Employee deletedEmp = check rainier->/employees.delete({empNo: emp.empNo});
        io:println("Deleted employee: ", deletedEmp);
    }

    // http:Client httpClient = check new ("http://localhost:9090");
    // json j = check httpClient->/employees.get;
    // This give an error because Salary is a closed record
    stream<Salary, error?> salaryStream = rainier->/salaries.selectMany;
    io:println(salaryStream);

    stream<record {|*Salary; Employee employee;|}, error?> salariesWithEmployee = rainier->/salaries.selectMany;
    io:println(salariesWithEmployee);

    Salary? salary = check rainier->/salaries.selectUnique(uniqueKey = {empNo: "10001", fromDate: {year: 2002, month: 6, day: 22}});
    io:println("Salary: ", salary);

    record {|
        int salary;
        readonly time:Date fromDate;
        time:Date toDate;
        record {|string firstName; string lastName;|} employee;
    |}? salaryDetails = check rainier->/salaries.selectUnique(uniqueKey = {empNo: "10001", fromDate: {year: 2002, month: 6, day: 22}});
    io:println("Salary: ", salaryDetails);

    // mysql:Client foo = check new();
    // stream<Employee, error?> es = foo->query(`SELECT * FROM employees`);

    // io:println(es);

    // Employee[] employees = check from var emp in foo->query(`SELECT * FROM employees`) select emp;

    record {|int salary;|}? salary1 = check rainier->/salaries.selectUnique(uniqueKey = {empNo: "10001", fromDate: {year: 2002, month: 6, day: 22}});
    io:println("Salary: ", salary1);

    Salary? _ = check rainier->/salaries.selectUnique(uniqueKey = {empNo: "10001", fromDate: {year: 2002, month: 6, day: 22}});
}
