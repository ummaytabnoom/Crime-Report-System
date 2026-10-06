package utils;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/** Shared profile-picture loading helpers used by JSP pages. */
public final class ProfileUtil {
    private ProfileUtil() {
    }

    public static byte[] getProfilePicture(Connection connection, String username)
            throws SQLException, IOException {
        if (connection == null || username == null || username.isBlank()) {
            return null;
        }

        String sql = "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, username);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return null;
                }
                return readBlob(resultSet.getBlob("PROFILE_PICTURE"));
            }
        }
    }

    public static byte[] getProfilePictureById(Connection connection, int userId)
            throws SQLException, IOException {
        String sql = "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE ID = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return null;
                }
                return readBlob(resultSet.getBlob("PROFILE_PICTURE"));
            }
        }
    }

    private static byte[] readBlob(java.sql.Blob blob) throws SQLException, IOException {
        if (blob == null) {
            return null;
        }

        try (InputStream input = blob.getBinaryStream();
             ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[4096];
            int count;
            while ((count = input.read(buffer)) != -1) {
                output.write(buffer, 0, count);
            }
            return output.toByteArray();
        }
    }
}
