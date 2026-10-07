using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ERP.Migrations
{
    /// <inheritdoc />
    public partial class UpdateUserRoleTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserRole_Users_AssignedByUserUserId",
                schema: "Identity",
                table: "UserRole");

            migrationBuilder.DropIndex(
                name: "IX_UserRole_AssignedByUserUserId",
                schema: "Identity",
                table: "UserRole");

            migrationBuilder.DropColumn(
                name: "AssignedByUserUserId",
                schema: "Identity",
                table: "UserRole");

            migrationBuilder.CreateIndex(
                name: "IX_UserRole_AssignedBy",
                schema: "Identity",
                table: "UserRole",
                column: "AssignedBy");

            migrationBuilder.AddForeignKey(
                name: "FK_UserRole_Users_AssignedBy",
                schema: "Identity",
                table: "UserRole",
                column: "AssignedBy",
                principalSchema: "Identity",
                principalTable: "Users",
                principalColumn: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserRole_Users_AssignedBy",
                schema: "Identity",
                table: "UserRole");

            migrationBuilder.DropIndex(
                name: "IX_UserRole_AssignedBy",
                schema: "Identity",
                table: "UserRole");

            migrationBuilder.AddColumn<Guid>(
                name: "AssignedByUserUserId",
                schema: "Identity",
                table: "UserRole",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_UserRole_AssignedByUserUserId",
                schema: "Identity",
                table: "UserRole",
                column: "AssignedByUserUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserRole_Users_AssignedByUserUserId",
                schema: "Identity",
                table: "UserRole",
                column: "AssignedByUserUserId",
                principalSchema: "Identity",
                principalTable: "Users",
                principalColumn: "UserId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
